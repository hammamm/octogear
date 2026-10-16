import '../../domain/entities/provider_dashboard.dart';
import '../../domain/repositories/provider_dashboard_repository.dart';
import '../data_sources/provider_dashboard_remote_data_source.dart';

class ProviderDashboardRepositoryImpl implements ProviderDashboardRepository {
  const ProviderDashboardRepositoryImpl(this.remote);
  final ProviderDashboardRemoteDataSource remote;
  @override
  Future<ProviderDashboard> getDashboard(ProviderDashboardQuery query) async =>
      (await remote.getDashboard(query)).toEntity();
  @override
  Future<ProviderDashboardActivityPage> getActivity(
    ProviderDashboardActivityQuery query, {
    int page = 1,
  }) async => (await remote.getActivity(query, page: page)).toEntity();
}
