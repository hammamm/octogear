import 'marketplace_store.dart';

/// One server-authoritative page of customer storefront results.
class StorefrontPage {
  const StorefrontPage({
    required this.stores,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final List<MarketplaceStore> stores;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasNextPage => currentPage < lastPage;
}
