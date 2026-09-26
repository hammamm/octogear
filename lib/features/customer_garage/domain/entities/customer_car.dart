/// A localized reference returned as part of a saved customer car.
class CustomerCarReference {
  const CustomerCarReference({required this.id, required this.name});

  final int id;
  final String name;
}

/// Safe metadata for one private customer-car image.
///
/// [url] is the API-provided relative or absolute stream URL. It is never a
/// storage path and must be requested with the current bearer token.
class CustomerCarPicture {
  const CustomerCarPicture({
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

/// A car saved by the authenticated customer.
///
/// This entity uses the correct domain term `licensePlateNumber`. The Laravel
/// transport field remains `vehicle_plat_number` until that external API
/// contract is deliberately versioned.
class CustomerCar {
  const CustomerCar({
    required this.id,
    required this.manufacturingYear,
    required this.licensePlateNumber,
    required this.carName,
    required this.color,
    required this.fuelType,
    required this.pictures,
    required this.createdAt,
  });

  final int id;
  final int manufacturingYear;
  final String licensePlateNumber;
  final CustomerCarReference carName;
  final CustomerCarReference color;
  final CustomerCarReference fuelType;
  final List<CustomerCarPicture> pictures;
  final DateTime createdAt;
}
