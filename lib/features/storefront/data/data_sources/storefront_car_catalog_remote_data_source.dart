import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../domain/entities/storefront_car_catalog.dart';
import '../models/storefront_car_catalog_dto.dart';

class StorefrontComponentsRemotePage {
  const StorefrontComponentsRemotePage({
    required this.components,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
  final List<StorefrontCarComponentDto> components;
  final int currentPage;
  final int lastPage;
  final int total;
}

class StorefrontCarCatalogRemoteDataSource {
  const StorefrontCarCatalogRemoteDataSource(this._apiClient);
  final ApiClient _apiClient;

  Future<StorefrontCarDetailsDto> fetchCarDetails(StorefrontCarKey key) async {
    final response = await _apiClient.get<StorefrontCarDetailsDto>(
      'stores/${key.storeId}/cars/${key.carId}',
      requiresAuthentication: true,
      decode: (json) => StorefrontCarDetailsDto.fromJson(json, key),
    );
    return response.data ?? (throw const ApiFailure.unexpected());
  }

  Future<StorefrontComponentsRemotePage> fetchComponents(
    StorefrontCarKey key, {
    required int page,
  }) async {
    final response = await _apiClient.get<List<StorefrontCarComponentDto>>(
      'stores/${key.storeId}/cars/${key.carId}/components',
      requiresAuthentication: true,
      queryParameters: {'page': page},
      decode: (json) {
        if (json is! List) {
          throw const FormatException('Expected component list.');
        }
        return List.unmodifiable(json.map(StorefrontCarComponentDto.fromJson));
      },
    );
    final pagination = response.pagination;
    if (response.data == null ||
        pagination == null ||
        pagination.currentPage != page) {
      throw const ApiFailure.unexpected();
    }
    return StorefrontComponentsRemotePage(
      components: response.data!,
      currentPage: pagination.currentPage,
      lastPage: pagination.lastPage,
      total: pagination.total,
    );
  }
}
