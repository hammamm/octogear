import '../../../../core/api/api_failure.dart';
import '../../domain/entities/marketplace_store.dart';
import '../../domain/entities/storefront_filter_options.dart';
import '../../domain/entities/storefront_filters.dart';
import '../../domain/entities/storefront_page.dart';
import '../../domain/entities/storefront_store_cars_page.dart';
import '../../domain/entities/storefront_store_details.dart';
import '../../domain/repositories/storefront_repository.dart';
import '../data_sources/storefront_remote_data_source.dart';
import '../models/storefront_reference_dto.dart';

/// Maps the server's storefront transport DTOs to product-facing domain data.
class StorefrontRepositoryImpl implements StorefrontRepository {
  const StorefrontRepositoryImpl({
    required StorefrontRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final StorefrontRemoteDataSource _remoteDataSource;

  @override
  Future<StorefrontPage> searchStores(
    StorefrontFilters filters, {
    required int page,
  }) async {
    try {
      final response = await _remoteDataSource.fetchStores(filters, page: page);
      return StorefrontPage(
        stores: List.unmodifiable(
          response.stores.map((store) => store.toEntity()),
        ),
        currentPage: response.currentPage,
        lastPage: response.lastPage,
        perPage: response.perPage,
        total: response.total,
      );
    } on ApiFailure {
      rethrow;
    } on FormatException {
      throw const ApiFailure.unexpected();
    }
  }

  @override
  Future<StorefrontFilterOptions> getFilterOptions() async {
    try {
      final responses = await Future.wait<List<StorefrontReferenceDto>>([
        _remoteDataSource.fetchCities(),
        _remoteDataSource.fetchCompanies(),
      ]);
      return StorefrontFilterOptions(
        cities: _toReferences(responses[0]),
        companies: _toReferences(responses[1]),
      );
    } on ApiFailure {
      rethrow;
    } on FormatException {
      throw const ApiFailure.unexpected();
    }
  }

  @override
  Future<StorefrontStoreDetails> getStoreDetails(int storeId) async {
    try {
      return (await _remoteDataSource.fetchStoreDetails(storeId)).toEntity();
    } on ApiFailure {
      rethrow;
    } on FormatException {
      throw const ApiFailure.unexpected();
    }
  }

  @override
  Future<StorefrontStoreCarsPage> getStoreCars(
    int storeId, {
    required int page,
  }) async {
    try {
      final response = await _remoteDataSource.fetchStoreCars(
        storeId,
        page: page,
      );
      return StorefrontStoreCarsPage(
        cars: List.unmodifiable(response.cars.map((car) => car.toEntity())),
        currentPage: response.currentPage,
        lastPage: response.lastPage,
        perPage: response.perPage,
        total: response.total,
      );
    } on ApiFailure {
      rethrow;
    } on FormatException {
      throw const ApiFailure.unexpected();
    }
  }

  List<StorefrontReference> _toReferences(List<StorefrontReferenceDto> values) {
    return List.unmodifiable(values.map((value) => value.toEntity()));
  }
}
