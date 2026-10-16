import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/api/api_providers.dart';
import '../../../../core/localization/app_locale_controller.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../../data/data_sources/provider_managed_orders_remote_data_source.dart';
import '../../data/repositories/provider_managed_orders_repository_impl.dart';
import '../../domain/entities/provider_managed_order.dart';
import '../../domain/repositories/provider_managed_orders_repository.dart';
import '../../domain/use_cases/provider_managed_order_use_cases.dart';

final providerManagedOrdersRepositoryProvider =
    Provider<ProviderManagedOrdersRepository>(
      (ref) => ProviderManagedOrdersRepositoryImpl(
        ProviderManagedOrdersRemoteDataSource(ref.watch(apiClientProvider)),
      ),
    );
final getProviderManagedOrdersProvider = Provider(
  (ref) => GetProviderManagedOrders(
    ref.watch(providerManagedOrdersRepositoryProvider),
  ),
);
final getProviderManagedOrderProvider = Provider(
  (ref) => GetProviderManagedOrder(
    ref.watch(providerManagedOrdersRepositoryProvider),
  ),
);
final respondToProviderDirectOrderProvider = Provider(
  (ref) => RespondToProviderDirectOrder(
    ref.watch(providerManagedOrdersRepositoryProvider),
  ),
);

int? _owner(SessionOutcome? session) =>
    session is AuthenticatedSession && session.user.role == AppUserRole.provider
    ? session.user.id
    : null;

final providerManagedOrderFilterProvider = NotifierProvider.autoDispose
    .family<ProviderOrderFilter, String?, ProviderOrderKind>(
      ProviderOrderFilter.new,
    );

class ProviderOrderFilter extends Notifier<String?> {
  ProviderOrderFilter(this.kind);
  final ProviderOrderKind kind;
  @override
  String? build() {
    ref.watch(sessionControllerProvider);
    return kind == ProviderOrderKind.paid ? 'paid' : 'pending';
  }

  void select(String? value) => state = value;
}

class ProviderManagedOrdersState {
  const ProviderManagedOrdersState(
    this.page, {
    this.loadingMore = false,
    this.error,
  });
  final ProviderManagedOrdersPage page;
  final bool loadingMore;
  final Object? error;
}

final providerManagedOrdersProvider = AsyncNotifierProvider.autoDispose
    .family<
      ProviderManagedOrdersController,
      ProviderManagedOrdersState,
      ProviderOrderQuery
    >(ProviderManagedOrdersController.new, retry: (_, _) => null);

class ProviderManagedOrdersController
    extends AsyncNotifier<ProviderManagedOrdersState> {
  ProviderManagedOrdersController(this.query);
  final ProviderOrderQuery query;
  int _generation = 0;
  int? _user;
  @override
  Future<ProviderManagedOrdersState> build() async {
    ++_generation;
    ref.onDispose(() => ++_generation);
    _user = _owner(ref.watch(sessionControllerProvider).asData?.value);
    ref.watch(appLocaleProvider);
    if (_user == null) {
      throw const ApiFailure(type: ApiFailureType.unauthorized);
    }
    return ProviderManagedOrdersState(
      await ref.watch(getProviderManagedOrdersProvider).call(query),
    );
  }

  bool _current(int generation) =>
      ref.mounted &&
      generation == _generation &&
      _user == _owner(ref.read(sessionControllerProvider).asData?.value);
  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (state.isLoading ||
        current == null ||
        current.loadingMore ||
        !current.page.hasMore) {
      return;
    }
    final generation = _generation;
    final get = ref.read(getProviderManagedOrdersProvider);
    state = AsyncData(
      ProviderManagedOrdersState(current.page, loadingMore: true),
    );
    try {
      final next = await get(query, page: current.page.page + 1);
      if (!_current(generation)) return;
      final items = {
        for (final item in current.page.items) item.id: item,
        for (final item in next.items) item.id: item,
      };
      state = AsyncData(
        ProviderManagedOrdersState(
          ProviderManagedOrdersPage(
            List.unmodifiable(items.values),
            next.page,
            next.lastPage,
            next.total,
          ),
        ),
      );
    } catch (error) {
      if (_current(generation)) {
        state = AsyncData(
          ProviderManagedOrdersState(current.page, error: error),
        );
      }
    }
  }
}

final providerManagedOrderProvider = FutureProvider.autoDispose
    .family<ProviderManagedOrder, ProviderOrderKey>((ref, key) {
      final user = _owner(ref.watch(sessionControllerProvider).asData?.value);
      ref.watch(appLocaleProvider);
      if (user == null) {
        throw const ApiFailure(type: ApiFailureType.unauthorized);
      }
      return ref.watch(getProviderManagedOrderProvider).call(key);
    }, retry: (_, _) => null);

class ProviderDirectOrderActionState {
  const ProviderDirectOrderActionState({
    this.busy = false,
    this.uncertain = false,
    this.error,
  });
  final bool busy, uncertain;
  final Object? error;
}

final providerDirectOrderActionsProvider = NotifierProvider.autoDispose
    .family<ProviderDirectOrderActions, ProviderDirectOrderActionState, int>(
      ProviderDirectOrderActions.new,
    );

class ProviderDirectOrderActions
    extends Notifier<ProviderDirectOrderActionState> {
  ProviderDirectOrderActions(this.id);
  final int id;
  int _generation = 0;
  int? _user;
  @override
  ProviderDirectOrderActionState build() {
    ++_generation;
    ref.onDispose(() => ++_generation);
    _user = _owner(ref.watch(sessionControllerProvider).asData?.value);
    return const ProviderDirectOrderActionState();
  }

  bool _current(int generation) =>
      ref.mounted &&
      generation == _generation &&
      _user == _owner(ref.read(sessionControllerProvider).asData?.value);
  void _refresh() {
    ref.invalidate(providerManagedOrdersProvider);
    ref.invalidate(
      providerManagedOrderProvider((kind: ProviderOrderKind.direct, id: id)),
    );
    ref.invalidate(
      providerManagedOrderProvider((kind: ProviderOrderKind.paid, id: id)),
    );
  }

  Future<ProviderManagedOrder?> respond(
    ProviderManagedOrder order, {
    required bool accept,
  }) async {
    if (state.busy || state.uncertain || _user == null) return null;
    if (order.id != id) throw ArgumentError('Mismatched order.');
    final generation = _generation;
    state = const ProviderDirectOrderActionState(busy: true);
    try {
      final result = await ref
          .read(respondToProviderDirectOrderProvider)
          .call(order, accept: accept);
      if (!_current(generation)) return null;
      state = const ProviderDirectOrderActionState();
      _refresh();
      return result;
    } catch (error) {
      if (_current(generation)) {
        final uncertain =
            error is! ApiFailure ||
            [
              ApiFailureType.timeout,
              ApiFailureType.noConnection,
              ApiFailureType.server,
              ApiFailureType.unexpected,
            ].contains(error.type);
        state = ProviderDirectOrderActionState(
          uncertain: uncertain,
          error: error,
        );
      }
      return null;
    }
  }

  // Read the current server state before offering another explicit, idempotent action.
  Future<ProviderManagedOrder?> check() async {
    if (state.busy || !state.uncertain || _user == null) return null;
    final generation = _generation;
    state = const ProviderDirectOrderActionState(busy: true, uncertain: true);
    try {
      final result = await ref.read(getProviderManagedOrderProvider).call((
        kind: ProviderOrderKind.direct,
        id: id,
      ));
      if (!_current(generation)) return null;
      state = const ProviderDirectOrderActionState();
      _refresh();
      return result;
    } catch (error) {
      if (_current(generation)) {
        state = ProviderDirectOrderActionState(uncertain: true, error: error);
      }
      return null;
    }
  }
}
