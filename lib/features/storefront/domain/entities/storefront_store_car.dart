import 'marketplace_store.dart';

/// A customer-safe summary of one vehicle in a marketplace store's inventory.
class StorefrontStoreCar {
  const StorefrontStoreCar({
    required this.id,
    required this.manufacturingYear,
    required this.carName,
    required this.color,
    required this.fuelType,
    required this.componentsCount,
    required this.pictures,
  });

  final int id;
  final int manufacturingYear;
  final StorefrontReference carName;
  final StorefrontReference color;
  final StorefrontReference fuelType;
  final int componentsCount;
  final List<StorefrontStoreCarPicture> pictures;
}

class StorefrontStoreCarPicture {
  const StorefrontStoreCarPicture({
    required this.id,
    required this.url,
    required this.mimeType,
    required this.sizeBytes,
    required this.sortOrder,
  });

  final int id;
  final String url;
  final String mimeType;
  final int sizeBytes;
  final int sortOrder;
}
