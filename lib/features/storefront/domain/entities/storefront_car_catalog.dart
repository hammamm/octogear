import 'marketplace_store.dart';
import 'storefront_store_car.dart';

typedef StorefrontCarKey = ({int storeId, int carId});

class StorefrontCarDetails {
  const StorefrontCarDetails({
    required this.car,
    required this.store,
    required this.company,
    required this.sections,
  });

  final StorefrontStoreCar car;
  final StorefrontReference store;
  final StorefrontReference? company;
  final List<StorefrontCarSection> sections;
}

enum StorefrontSectionCondition { okay, damaged, unknown }

class StorefrontCarSection {
  const StorefrontCarSection({
    required this.id,
    required this.name,
    required this.condition,
  });
  final int id;
  final String name;
  final StorefrontSectionCondition condition;
}

class StorefrontCarComponent {
  const StorefrontCarComponent({
    required this.id,
    required this.component,
    required this.section,
    required this.priceMinor,
    required this.currency,
    required this.priceScale,
    required this.stockQuantity,
    required this.partNumber,
    required this.description,
    required this.warrantyMonths,
  });

  final int id;
  final StorefrontReference component;
  final StorefrontReference? section;
  final int priceMinor;
  final String currency;
  final int priceScale;
  final int stockQuantity;
  final String? partNumber;
  final String? description;
  final int? warrantyMonths;
  bool get inStock => stockQuantity > 0;
}

class StorefrontComponentsPage {
  const StorefrontComponentsPage({
    required this.components,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
  final List<StorefrontCarComponent> components;
  final int currentPage;
  final int lastPage;
  final int total;
  bool get hasNextPage => currentPage < lastPage;
}
