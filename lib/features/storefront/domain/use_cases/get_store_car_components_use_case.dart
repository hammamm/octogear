import '../entities/storefront_car_catalog.dart';
import '../repositories/storefront_car_catalog_repository.dart';

class GetStoreCarComponentsUseCase {
  const GetStoreCarComponentsUseCase(this._repository);
  final StorefrontCarCatalogRepository _repository;
  Future<StorefrontComponentsPage> call(
    StorefrontCarKey key, {
    required int page,
  }) => _repository.getComponents(key, page: page);
}
