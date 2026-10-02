import '../../../../core/api/reference_list_loader.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../domain/entities/storefront_filters.dart';
import '../models/marketplace_store_dto.dart';
import '../models/storefront_reference_dto.dart';
import '../models/storefront_store_car_dto.dart';
import '../models/storefront_store_details_dto.dart';

/// Network-only access to the customer storefront APIs.
///
/// It owns endpoint paths and transport decoding. The shared [ApiClient]
/// supplies bearer authentication, language headers, timeout policy, and safe
/// conversion of HTTP errors to [ApiFailure].
abstract interface class StorefrontRemoteDataSource {
  Future<StorefrontRemotePage> fetchStores(
    StorefrontFilters filters, {
    required int page,
  });

  Future<List<StorefrontReferenceDto>> fetchCities();

  Future<List<StorefrontReferenceDto>> fetchCompanies();

  Future<StorefrontStoreDetailsDto> fetchStoreDetails(int storeId);

  Future<StorefrontStoreCarsRemotePage> fetchStoreCars(
    int storeId, {
    required int page,
  });
}

class StorefrontRemotePage {
  const StorefrontRemotePage({
    required this.stores,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final List<MarketplaceStoreDto> stores;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
}

class StorefrontStoreCarsRemotePage {
  const StorefrontStoreCarsRemotePage({
    required this.cars,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final List<StorefrontStoreCarDto> cars;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
}

class StorefrontRemoteDataSourceImpl implements StorefrontRemoteDataSource {
  const StorefrontRemoteDataSourceImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<StorefrontRemotePage> fetchStores(
    StorefrontFilters filters, {
    required int page,
  }) async {
    final queryParameters = <String, Object?>{'page': page};
    final query = filters.query.trim();
    if (query.isNotEmpty) queryParameters['query'] = query;
    if (filters.cityId != null) queryParameters['city_id'] = filters.cityId;
    if (filters.companyId != null) {
      queryParameters['company_id'] = filters.companyId;
    }

    final response = await _apiClient.get<List<MarketplaceStoreDto>>(
      'stores',
      requiresAuthentication: true,
      queryParameters: queryParameters,
      decode: marketplaceStoreListFromJson,
    );
    final stores = response.data;
    final pagination = response.pagination;
    if (stores == null || pagination == null) {
      throw const ApiFailure.unexpected();
    }

    return StorefrontRemotePage(
      stores: stores,
      currentPage: pagination.currentPage,
      lastPage: pagination.lastPage,
      perPage: pagination.perPage,
      total: pagination.total,
    );
  }

  @override
  Future<List<StorefrontReferenceDto>> fetchCities() {
    return _fetchReferences('reference/cities');
  }

  @override
  Future<List<StorefrontReferenceDto>> fetchCompanies() {
    return _fetchReferences('reference/companies');
  }

  @override
  Future<StorefrontStoreDetailsDto> fetchStoreDetails(int storeId) async {
    final response = await _apiClient.get<StorefrontStoreDetailsDto>(
      'stores/$storeId',
      requiresAuthentication: true,
      decode: StorefrontStoreDetailsDto.fromJson,
    );
    final store = response.data;
    if (store == null) throw const ApiFailure.unexpected();
    return store;
  }

  @override
  Future<StorefrontStoreCarsRemotePage> fetchStoreCars(
    int storeId, {
    required int page,
  }) async {
    final response = await _apiClient.get<List<StorefrontStoreCarDto>>(
      'stores/$storeId/cars',
      requiresAuthentication: true,
      queryParameters: {'page': page},
      decode: (data) => storefrontStoreCarListFromJson(data, storeId: storeId),
    );
    final cars = response.data;
    final pagination = response.pagination;
    if (cars == null || pagination == null) {
      throw const ApiFailure.unexpected();
    }

    return StorefrontStoreCarsRemotePage(
      cars: cars,
      currentPage: pagination.currentPage,
      lastPage: pagination.lastPage,
      perPage: pagination.perPage,
      total: pagination.total,
    );
  }

  Future<List<StorefrontReferenceDto>> _fetchReferences(String path) =>
      loadReferenceList(
        _apiClient,
        path,
        decode: storefrontReferenceListFromJson,
      );
}
