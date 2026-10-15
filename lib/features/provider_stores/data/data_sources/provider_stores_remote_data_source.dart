import '../../../../core/api/api_client.dart';
import '../../domain/entities/provider_store.dart';
import '../models/provider_store_dto.dart';

abstract interface class ProviderStoresRemoteDataSource {
  Future<List<ProviderStore>> fetchStores();
}

class ProviderStoresRemoteDataSourceImpl
    implements ProviderStoresRemoteDataSource {
  const ProviderStoresRemoteDataSourceImpl(this._api);
  final ApiClient _api;

  @override
  Future<List<ProviderStore>> fetchStores() async {
    final response = await _api.get<List<ProviderStore>>(
      'provider/stores',
      requiresAuthentication: true,
      decode: (data) {
        if (data is! List) {
          throw const FormatException('Invalid owned store list.');
        }
        return List.unmodifiable(data.map(ProviderStoreDto.fromJson));
      },
    );
    return response.data ??
        (throw const FormatException('Missing owned store list.'));
  }
}
