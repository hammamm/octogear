import '../entities/storefront_car_catalog.dart';

abstract interface class StorefrontCarCatalogRepository {
  Future<StorefrontCarDetails> getCarDetails(StorefrontCarKey key);
  Future<StorefrontComponentsPage> getComponents(
    StorefrontCarKey key, {
    required int page,
  });
}
