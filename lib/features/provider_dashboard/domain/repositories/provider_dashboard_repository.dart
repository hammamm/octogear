import '../entities/provider_dashboard.dart';

abstract interface class ProviderDashboardRepository {
  Future<ProviderDashboard> getDashboard(ProviderDashboardQuery query);
  Future<ProviderDashboardActivityPage> getActivity(
    ProviderDashboardActivityQuery query, {
    int page = 1,
  });
}
