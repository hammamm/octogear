/// A localized reference returned as part of a saved customer car.
class CustomerCarReference {
  const CustomerCarReference({required this.id, required this.name});

  final int id;
  final String name;
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
    required this.picturePaths,
    required this.createdAt,
  });

  final int id;
  final int manufacturingYear;
  final String licensePlateNumber;
  final CustomerCarReference carName;
  final CustomerCarReference color;
  final CustomerCarReference fuelType;
  final List<String> picturePaths;
  final DateTime createdAt;
}
