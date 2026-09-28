import '../../../../core/api/api_failure.dart';
import '../../domain/entities/storefront_car_catalog.dart';
import '../../domain/repositories/storefront_car_catalog_repository.dart';
import '../data_sources/storefront_car_catalog_remote_data_source.dart';

class StorefrontCarCatalogRepositoryImpl
    implements StorefrontCarCatalogRepository {
  const StorefrontCarCatalogRepositoryImpl(this._remote);
  final StorefrontCarCatalogRemoteDataSource _remote;

  @override
  Future<StorefrontCarDetails> getCarDetails(StorefrontCarKey key) async {
    try {
      return (await _remote.fetchCarDetails(key)).toEntity();
    } on FormatException {
      throw const ApiFailure.unexpected();
    }
  }

  @override
  Future<StorefrontComponentsPage> getComponents(
    StorefrontCarKey key, {
    required int page,
  }) async {
    try {
      final data = await _remote.fetchComponents(key, page: page);
      return StorefrontComponentsPage(
        components: List.unmodifiable(
          data.components.map((part) => part.toEntity()),
        ),
        currentPage: data.currentPage,
        lastPage: data.lastPage,
        total: data.total,
      );
    } on FormatException {
      throw const ApiFailure.unexpected();
    }
  }
}
