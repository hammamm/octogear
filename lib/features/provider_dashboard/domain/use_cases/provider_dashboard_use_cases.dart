import '../entities/provider_dashboard.dart';
import '../repositories/provider_dashboard_repository.dart';

class GetProviderDashboard {
  const GetProviderDashboard(this.repository);
  final ProviderDashboardRepository repository;
  Future<ProviderDashboard> call(ProviderDashboardQuery query) =>
      repository.getDashboard(query);
}

class GetProviderDashboardActivity {
  const GetProviderDashboardActivity(this.repository);
  final ProviderDashboardRepository repository;
  Future<ProviderDashboardActivityPage> call(
    ProviderDashboardActivityQuery query, {
    int page = 1,
  }) => repository.getActivity(query, page: page);
}
