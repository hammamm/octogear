import '../entities/storefront_filter_options.dart';
import '../entities/storefront_filters.dart';
import '../entities/storefront_page.dart';
import '../entities/storefront_store_cars_page.dart';
import '../entities/storefront_store_details.dart';

abstract interface class StorefrontRepository {
  Future<StorefrontPage> searchStores(
    StorefrontFilters filters, {
    required int page,
  });

  Future<StorefrontFilterOptions> getFilterOptions();

  Future<StorefrontStoreDetails> getStoreDetails(int storeId);

  Future<StorefrontStoreCarsPage> getStoreCars(
    int storeId, {
    required int page,
  });
}
