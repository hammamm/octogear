import '../entities/provider_store.dart';
import '../repositories/provider_stores_repository.dart';

class GetProviderStores {
  const GetProviderStores(this._repository);
  final ProviderStoresRepository _repository;

  Future<List<ProviderStore>> call() => _repository.fetchStores();
}
