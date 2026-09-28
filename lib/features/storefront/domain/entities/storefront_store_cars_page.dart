import 'storefront_store_car.dart';

/// One authoritative server page of inventory for a single marketplace store.
class StorefrontStoreCarsPage {
  const StorefrontStoreCarsPage({
    required this.cars,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final List<StorefrontStoreCar> cars;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasNextPage => currentPage < lastPage;
}
