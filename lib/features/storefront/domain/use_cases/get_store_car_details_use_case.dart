import '../entities/storefront_car_catalog.dart';
import '../repositories/storefront_car_catalog_repository.dart';

class GetStoreCarDetailsUseCase {
  const GetStoreCarDetailsUseCase(this._repository);
  final StorefrontCarCatalogRepository _repository;
  Future<StorefrontCarDetails> call(StorefrontCarKey key) =>
      _repository.getCarDetails(key);
}
