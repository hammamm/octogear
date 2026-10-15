import '../../domain/entities/provider_store.dart';
import '../../domain/repositories/provider_stores_repository.dart';
import '../data_sources/provider_stores_remote_data_source.dart';

class ProviderStoresRepositoryImpl implements ProviderStoresRepository {
  const ProviderStoresRepositoryImpl(this._remote);
  final ProviderStoresRemoteDataSource _remote;

  @override
  Future<List<ProviderStore>> fetchStores() => _remote.fetchStores();
}
