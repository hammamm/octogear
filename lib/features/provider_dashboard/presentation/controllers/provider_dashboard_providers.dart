import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/api/api_providers.dart';
import '../../../../core/localization/app_locale_controller.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../../data/data_sources/provider_dashboard_remote_data_source.dart';
import '../../data/repositories/provider_dashboard_repository_impl.dart';
import '../../domain/entities/provider_dashboard.dart';
import '../../domain/repositories/provider_dashboard_repository.dart';
import '../../domain/use_cases/provider_dashboard_use_cases.dart';

final providerDashboardRepositoryProvider =
    Provider<ProviderDashboardRepository>(
      (ref) => ProviderDashboardRepositoryImpl(
        ProviderDashboardRemoteDataSource(ref.watch(apiClientProvider)),
      ),
    );
final getProviderDashboardProvider = Provider(
  (ref) => GetProviderDashboard(ref.watch(providerDashboardRepositoryProvider)),
);
final getProviderDashboardActivityProvider = Provider(
  (ref) => GetProviderDashboardActivity(
    ref.watch(providerDashboardRepositoryProvider),
  ),
);

int? _owner(SessionOutcome? session) =>
    session is AuthenticatedSession && session.user.role == AppUserRole.provider
    ? session.user.id
    : null;

final _dashboardOwnerProvider = Provider<int?>(
  (ref) => _owner(ref.watch(sessionControllerProvider).asData?.value),
);

final providerDashboardFilterProvider =
    NotifierProvider<ProviderDashboardFilter, ProviderDashboardQuery>(
      ProviderDashboardFilter.new,
    );

class ProviderDashboardFilter extends Notifier<ProviderDashboardQuery> {
  @override
  ProviderDashboardQuery build() {
    ref.watch(_dashboardOwnerProvider);
    return (storeId: null, period: ProviderDashboardPeriod.month);
  }

  void selectStore(int? storeId) {
    if (storeId != null && storeId < 1) throw ArgumentError.value(storeId);
    state = (storeId: storeId, period: state.period);
  }

  void selectPeriod(ProviderDashboardPeriod period) =>
      state = (storeId: state.storeId, period: period);
}

final providerDashboardProvider = FutureProvider.autoDispose<ProviderDashboard>(
  (ref) {
    final owner = ref.watch(_dashboardOwnerProvider);
    final query = ref.watch(providerDashboardFilterProvider);
    ref.watch(appLocaleProvider);
    if (owner == null) {
      throw const ApiFailure(type: ApiFailureType.unauthorized);
    }
    return ref.watch(getProviderDashboardProvider).call(query);
  },
  retry: (_, _) => null,
);

class ProviderDashboardActivityState {
  const ProviderDashboardActivityState(
    this.page, {
    this.loadingMore = false,
    this.error,
  });
  final ProviderDashboardActivityPage page;
  final bool loadingMore;
  final Object? error;
}

final providerDashboardActivityProvider = AsyncNotifierProvider.autoDispose
    .family<
      ProviderDashboardActivityController,
      ProviderDashboardActivityState,
      ProviderDashboardActivityQuery
    >(ProviderDashboardActivityController.new, retry: (_, _) => null);

class ProviderDashboardActivityController
    extends AsyncNotifier<ProviderDashboardActivityState> {
  ProviderDashboardActivityController(this.query);
  final ProviderDashboardActivityQuery query;
  int _generation = 0;
  int? _user;

  @override
  Future<ProviderDashboardActivityState> build() async {
    final generation = ++_generation;
    ref.onDispose(() => ++_generation);
    _user = ref.watch(_dashboardOwnerProvider);
    ref.watch(appLocaleProvider);
    if (_user == null) {
      throw const ApiFailure(type: ApiFailureType.unauthorized);
    }
    final page = await ref
        .watch(getProviderDashboardActivityProvider)
        .call(query);
    if (!_current(generation)) {
      throw const ApiFailure(type: ApiFailureType.unauthorized);
    }
    return ProviderDashboardActivityState(page);
  }

  bool _current(int generation) =>
      ref.mounted &&
      generation == _generation &&
      _user == ref.read(_dashboardOwnerProvider);

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (state.isLoading ||
        current == null ||
        current.loadingMore ||
        !current.page.hasMore) {
      return;
    }
    final generation = _generation;
    final get = ref.read(getProviderDashboardActivityProvider);
    state = AsyncData(
      ProviderDashboardActivityState(current.page, loadingMore: true),
    );
    try {
      final next = await get(query, page: current.page.page + 1);
      if (!_current(generation)) return;
      final items = {
        for (final item in current.page.items) item.id: item,
        for (final item in next.items) item.id: item,
      };
      state = AsyncData(
        ProviderDashboardActivityState(
          ProviderDashboardActivityPage(
            items: List.unmodifiable(items.values),
            page: next.page,
            lastPage: next.lastPage,
            total: next.total,
          ),
        ),
      );
    } catch (error) {
      if (_current(generation)) {
        state = AsyncData(
          ProviderDashboardActivityState(current.page, error: error),
        );
      }
    }
  }
}
