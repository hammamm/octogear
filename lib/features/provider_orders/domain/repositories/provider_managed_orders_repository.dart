import '../entities/provider_managed_order.dart';

abstract interface class ProviderManagedOrdersRepository {
  Future<ProviderManagedOrdersPage> list(
    ProviderOrderQuery query, {
    int page = 1,
  });
  Future<ProviderManagedOrder> get(ProviderOrderKey key);
  Future<ProviderManagedOrder> respond(
    ProviderManagedOrder order, {
    required bool accept,
  });
}
