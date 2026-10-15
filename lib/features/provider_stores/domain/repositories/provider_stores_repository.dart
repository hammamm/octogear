import '../entities/provider_store.dart';

abstract interface class ProviderStoresRepository {
  Future<List<ProviderStore>> fetchStores();
}
