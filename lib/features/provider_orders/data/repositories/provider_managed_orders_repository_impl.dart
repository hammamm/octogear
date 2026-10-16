import '../../domain/entities/provider_managed_order.dart';
import '../../domain/repositories/provider_managed_orders_repository.dart';
import '../data_sources/provider_managed_orders_remote_data_source.dart';

class ProviderManagedOrdersRepositoryImpl
    implements ProviderManagedOrdersRepository {
  const ProviderManagedOrdersRepositoryImpl(this.remote);
  final ProviderManagedOrdersRemoteDataSource remote;
  @override
  Future<ProviderManagedOrdersPage> list(
    ProviderOrderQuery query, {
    int page = 1,
  }) async => (await remote.list(query, page: page)).toEntity();
  @override
  Future<ProviderManagedOrder> get(ProviderOrderKey key) async =>
      (await remote.get(key)).toEntity();
  @override
  Future<ProviderManagedOrder> respond(
    ProviderManagedOrder order, {
    required bool accept,
  }) async => (await remote.respond(order, accept: accept)).toEntity();
}
