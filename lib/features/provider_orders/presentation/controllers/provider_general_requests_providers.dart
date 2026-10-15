import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_failure.dart';
import '../../../../core/api/api_providers.dart';
import '../../../../core/localization/app_locale_controller.dart';
import '../../../../core/storage/provider_order_filter_storage.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../../data/data_sources/provider_general_requests_remote_data_source.dart';
import '../../data/repositories/provider_general_requests_repository_impl.dart';
import '../../domain/entities/provider_general_request.dart';
import '../../domain/repositories/provider_general_requests_repository.dart';
import '../../domain/use_cases/get_provider_general_requests.dart';

final providerGeneralRequestsRepositoryProvider =
    Provider<ProviderGeneralRequestsRepository>(
      (ref) => ProviderGeneralRequestsRepositoryImpl(
        ProviderGeneralRequestsRemoteDataSource(ref.watch(apiClientProvider)),
      ),
    );
final getProviderGeneralRequestsProvider = Provider(
  (ref) => GetProviderGeneralRequests(
    ref.watch(providerGeneralRequestsRepositoryProvider),
  ),
);
final getProviderGeneralRequestProvider = Provider(
  (ref) => GetProviderGeneralRequest(
    ref.watch(providerGeneralRequestsRepositoryProvider),
  ),
);
final providerOrderFilterStorageProvider = Provider<ProviderOrderFilterStorage>(
  (ref) => ref.watch(appStorageProvider),
);

final providerOrderCityProvider =
    NotifierProvider<ProviderOrderCityController, int?>(
      ProviderOrderCityController.new,
    );

class ProviderOrderCityController extends Notifier<int?> {
  Future<void> _saving = Future.value();
  @override
  int? build() {
    final session = ref.watch(sessionControllerProvider).asData?.value;
    if (session is! AuthenticatedSession ||
        session.user.role != AppUserRole.provider) {
      return null;
    }
    return ref
        .watch(providerOrderFilterStorageProvider)
        .readProviderOrderCity(session.user.id);
  }

  Future<bool> select(int? cityId) async {
    if (cityId != null && cityId < 1) {
      throw ArgumentError.value(cityId, 'cityId');
    }
    final session = ref.read(sessionControllerProvider).asData?.value;
    if (session is! AuthenticatedSession ||
        session.user.role != AppUserRole.provider) {
      return false;
    }
    if (state == cityId) return true;
    final storage = ref.read(providerOrderFilterStorageProvider);
    state = cityId;
    // Serialize writes so a slow older selection cannot become the saved default.
    final save = _saving.then(
      (_) => storage.saveProviderOrderCity(session.user.id, cityId),
    );
    _saving = save.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    try {
      await save;
      return true;
    } catch (_) {
      return false;
    }
  }
}

class ProviderGeneralRequestsState {
  const ProviderGeneralRequestsState({
    required this.page,
    this.loadingMore = false,
    this.nextPageError,
  });
  final ProviderGeneralRequestsPage page;
  final bool loadingMore;
  final Object? nextPageError;
}

final providerGeneralRequestsProvider =
    AsyncNotifierProvider.autoDispose<
      ProviderGeneralRequestsController,
      ProviderGeneralRequestsState
    >(ProviderGeneralRequestsController.new, retry: (_, _) => null);

class ProviderGeneralRequestsController
    extends AsyncNotifier<ProviderGeneralRequestsState> {
  int _generation = 0;
  @override
  Future<ProviderGeneralRequestsState> build() async {
    ++_generation;
    ref.onDispose(() => ++_generation);
    final session = ref.watch(sessionControllerProvider).asData?.value;
    final cityId = ref.watch(providerOrderCityProvider);
    ref.watch(appLocaleProvider);
    if (session is! AuthenticatedSession ||
        session.user.role != AppUserRole.provider) {
      throw const ApiFailure(type: ApiFailureType.unauthorized);
    }
    return ProviderGeneralRequestsState(
      page: await ref
          .watch(getProviderGeneralRequestsProvider)
          .call(cityId: cityId),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading) return;
    final current = state.asData?.value;
    if (current == null || current.loadingMore || !current.page.hasMore) return;
    final generation = _generation;
    final cityId = ref.read(providerOrderCityProvider);
    final get = ref.read(getProviderGeneralRequestsProvider);
    state = AsyncData(
      ProviderGeneralRequestsState(page: current.page, loadingMore: true),
    );
    try {
      final next = await get(cityId: cityId, page: current.page.page + 1);
      if (!ref.mounted || generation != _generation) return;
      final items = {
        for (final item in current.page.items) item.id: item,
        for (final item in next.items) item.id: item,
      };
      state = AsyncData(
        ProviderGeneralRequestsState(
          page: ProviderGeneralRequestsPage(
            items: List.unmodifiable(items.values),
            page: next.page,
            lastPage: next.lastPage,
            total: next.total,
          ),
        ),
      );
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = AsyncData(
        ProviderGeneralRequestsState(page: current.page, nextPageError: error),
      );
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } catch (_) {
      /* The screen renders the failed first page. */
    }
  }
}

final providerGeneralRequestProvider = FutureProvider.autoDispose
    .family<ProviderGeneralRequest, int>((ref, id) {
      final session = ref.watch(sessionControllerProvider).asData?.value;
      ref.watch(appLocaleProvider);
      if (session is! AuthenticatedSession ||
          session.user.role != AppUserRole.provider) {
        throw const ApiFailure(type: ApiFailureType.unauthorized);
      }
      return ref.watch(getProviderGeneralRequestProvider).call(id);
    }, retry: (_, _) => null);
