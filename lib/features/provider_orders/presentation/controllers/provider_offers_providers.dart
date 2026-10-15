import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/api/api_providers.dart';
import '../../../../core/localization/app_locale_controller.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../../data/data_sources/provider_offers_remote_data_source.dart';
import '../../data/repositories/provider_offers_repository_impl.dart';
import '../../domain/entities/provider_offer.dart';
import '../../domain/repositories/provider_offers_repository.dart';
import '../../domain/use_cases/provider_offer_use_cases.dart';
import 'provider_general_requests_providers.dart';

final providerOffersRepositoryProvider = Provider<ProviderOffersRepository>(
  (ref) => ProviderOffersRepositoryImpl(
    ProviderOffersRemoteDataSource(ref.watch(apiClientProvider)),
  ),
);
final getProviderOffersProvider = Provider(
  (ref) => GetProviderOffers(ref.watch(providerOffersRepositoryProvider)),
);
final getProviderOfferProvider = Provider(
  (ref) => GetProviderOffer(ref.watch(providerOffersRepositoryProvider)),
);
final saveProviderOfferProvider = Provider(
  (ref) => SaveProviderOffer(ref.watch(providerOffersRepositoryProvider)),
);
final withdrawProviderOfferProvider = Provider(
  (ref) => WithdrawProviderOffer(ref.watch(providerOffersRepositoryProvider)),
);

int? _providerId(SessionOutcome? session) =>
    session is AuthenticatedSession && session.user.role == AppUserRole.provider
    ? session.user.id
    : null;

class ProviderOffersState {
  const ProviderOffersState(this.page, {this.loadingMore = false, this.error});
  final ProviderOffersPage page;
  final bool loadingMore;
  final Object? error;
}

final providerOffersProvider =
    AsyncNotifierProvider.autoDispose<
      ProviderOffersController,
      ProviderOffersState
    >(ProviderOffersController.new, retry: (_, _) => null);

class ProviderOffersController extends AsyncNotifier<ProviderOffersState> {
  int _generation = 0;
  @override
  Future<ProviderOffersState> build() async {
    ++_generation;
    ref.onDispose(() => ++_generation);
    final owner = _providerId(
      ref.watch(sessionControllerProvider).asData?.value,
    );
    ref.watch(appLocaleProvider);
    if (owner == null) {
      throw const ApiFailure(type: ApiFailureType.unauthorized);
    }
    return ProviderOffersState(
      await ref.watch(getProviderOffersProvider).call(),
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (state.isLoading ||
        current == null ||
        current.loadingMore ||
        !current.page.hasMore) {
      return;
    }
    final generation = _generation;
    final get = ref.read(getProviderOffersProvider);
    state = AsyncData(ProviderOffersState(current.page, loadingMore: true));
    try {
      final next = await get(page: current.page.page + 1);
      if (!ref.mounted || generation != _generation) return;
      final items = {
        for (final item in current.page.items) item.id: item,
        for (final item in next.items) item.id: item,
      };
      state = AsyncData(
        ProviderOffersState(
          ProviderOffersPage(
            List.unmodifiable(items.values),
            next.page,
            next.lastPage,
            next.total,
          ),
        ),
      );
    } catch (error) {
      if (ref.mounted && generation == _generation) {
        state = AsyncData(ProviderOffersState(current.page, error: error));
      }
    }
  }
}

final providerOfferProvider = FutureProvider.autoDispose
    .family<ProviderOffer, int>((ref, id) {
      final owner = _providerId(
        ref.watch(sessionControllerProvider).asData?.value,
      );
      ref.watch(appLocaleProvider);
      if (owner == null) {
        throw const ApiFailure(type: ApiFailureType.unauthorized);
      }
      return ref.watch(getProviderOfferProvider).call(id);
    }, retry: (_, _) => null);

typedef ProviderOfferActionKey = ({int orderId, int? offerId});

class ProviderOfferActionState {
  const ProviderOfferActionState({
    this.busy = false,
    this.uncertain = false,
    this.error,
    this.withdrawn = false,
  });
  final bool busy, uncertain, withdrawn;
  final Object? error;
}

final providerOfferActionsProvider = NotifierProvider.autoDispose
    .family<
      ProviderOfferActions,
      ProviderOfferActionState,
      ProviderOfferActionKey
    >(ProviderOfferActions.new);

class ProviderOfferActions extends Notifier<ProviderOfferActionState> {
  ProviderOfferActions(this.key);
  final ProviderOfferActionKey key;
  int _generation = 0;
  int? _owner;
  ProviderOfferCommand? _command;
  ProviderOffer? _withdrawing;
  @override
  ProviderOfferActionState build() {
    ++_generation;
    ref.onDispose(() => ++_generation);
    _owner = _providerId(ref.watch(sessionControllerProvider).asData?.value);
    _command = null;
    _withdrawing = null;
    return const ProviderOfferActionState();
  }

  bool _current(int generation) =>
      ref.mounted &&
      generation == _generation &&
      _owner == _providerId(ref.read(sessionControllerProvider).asData?.value);
  bool _ambiguous(Object error) =>
      error is! ApiFailure ||
      [
        ApiFailureType.timeout,
        ApiFailureType.noConnection,
        ApiFailureType.server,
        ApiFailureType.unexpected,
      ].contains(error.type);
  void _invalidate([int? offerId]) {
    ref.invalidate(providerOffersProvider);
    ref.invalidate(providerGeneralRequestsProvider);
    ref.invalidate(providerGeneralRequestProvider(key.orderId));
    if (offerId != null) ref.invalidate(providerOfferProvider(offerId));
  }

  Future<ProviderOffer?> save(ProviderOfferCommand command) async {
    if (state.busy || state.uncertain || _owner == null) return null;
    if (command.orderId != key.orderId || command.offerId != key.offerId) {
      throw ArgumentError('Mismatched action.');
    }
    final generation = _generation;
    _command = command;
    state = const ProviderOfferActionState(busy: true);
    try {
      final offer = await ref.read(saveProviderOfferProvider).call(command);
      if (!_current(generation)) return null;
      state = const ProviderOfferActionState();
      _invalidate(offer.id);
      return offer;
    } catch (error) {
      if (_current(generation)) {
        state = ProviderOfferActionState(
          error: error,
          uncertain: _ambiguous(error),
        );
      }
      return null;
    }
  }

  Future<bool> withdraw(ProviderOffer offer) async {
    if (state.busy || state.uncertain || _owner == null) return false;
    if (offer.id != key.offerId || offer.orderId != key.orderId) {
      throw ArgumentError('Mismatched action.');
    }
    final generation = _generation;
    _withdrawing = offer;
    state = const ProviderOfferActionState(busy: true);
    try {
      await ref.read(withdrawProviderOfferProvider).call(offer);
      if (!_current(generation)) return false;
      state = const ProviderOfferActionState(withdrawn: true);
      _invalidate(offer.id);
      return true;
    } catch (error) {
      if (_current(generation)) {
        state = ProviderOfferActionState(
          error: error,
          uncertain: _ambiguous(error),
        );
      }
      return false;
    }
  }

  /// Read-only reconciliation. Never automatically resend an ambiguous write.
  Future<ProviderOffer?> check() async {
    if (state.busy || !state.uncertain || _owner == null) return null;
    final generation = _generation;
    state = const ProviderOfferActionState(busy: true, uncertain: true);
    try {
      ProviderOffer? found;
      if (key.offerId != null) {
        found = await ref.read(getProviderOfferProvider).call(key.offerId!);
      } else if (_command != null) {
        final get = ref.read(getProviderOffersProvider);
        var page = 1;
        while (true) {
          final result = await get(page: page, orderId: key.orderId);
          if (!_current(generation)) return null;
          found = result.items
              .where((offer) => offer.storeId == _command!.storeId)
              .firstOrNull;
          if (found != null || !result.hasMore) break;
          page++;
        }
      }
      if (!_current(generation)) return null;
      state = ProviderOfferActionState(
        uncertain: found == null || _withdrawing != null,
      );
      if (found != null) _invalidate(found.id);
      return found;
    } catch (error) {
      if (!_current(generation)) return null;
      if (_withdrawing != null &&
          error is ApiFailure &&
          error.type == ApiFailureType.notFound) {
        state = const ProviderOfferActionState(withdrawn: true);
        _invalidate(key.offerId);
      } else {
        state = ProviderOfferActionState(uncertain: true, error: error);
      }
      return null;
    }
  }
}
