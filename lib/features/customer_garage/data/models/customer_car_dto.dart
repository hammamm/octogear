import '../../domain/entities/customer_car.dart';

class CustomerCarDto {
  const CustomerCarDto({
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
  final CustomerCarReferenceDto carName;
  final CustomerCarReferenceDto color;
  final CustomerCarReferenceDto fuelType;
  final List<String> picturePaths;
  final DateTime createdAt;

  factory CustomerCarDto.fromJson(Object? value) {
    final json = _objectMap(value, description: 'customer car');
    final id = _integer(json['id'], fieldName: 'customer car id');
    final manufacturingYear = _integer(
      json['manufacturing_year'],
      fieldName: 'customer car manufacturing_year',
    );
    final licensePlateNumber = _nonEmptyString(
      json['vehicle_plat_number'],
      fieldName: 'customer car vehicle_plat_number',
    );
    final createdAt = _dateTime(json['created_at']);

    return CustomerCarDto(
      id: id,
      manufacturingYear: manufacturingYear,
      licensePlateNumber: licensePlateNumber,
      carName: CustomerCarReferenceDto.fromJson(
        json['car_name'],
        description: 'customer car car_name',
      ),
      color: CustomerCarReferenceDto.fromJson(
        json['color'],
        description: 'customer car color',
      ),
      fuelType: CustomerCarReferenceDto.fromJson(
        json['fuel_type'],
        description: 'customer car fuel_type',
      ),
      picturePaths: _stringList(
        json['pictures'],
        fieldName: 'customer car pictures',
      ),
      createdAt: createdAt,
    );
  }

  CustomerCar toEntity() {
    return CustomerCar(
      id: id,
      manufacturingYear: manufacturingYear,
      licensePlateNumber: licensePlateNumber,
      carName: carName.toEntity(),
      color: color.toEntity(),
      fuelType: fuelType.toEntity(),
      picturePaths: List.unmodifiable(picturePaths),
      createdAt: createdAt,
    );
  }
}

class CustomerCarReferenceDto {
  const CustomerCarReferenceDto({required this.id, required this.name});

  final int id;
  final String name;

  factory CustomerCarReferenceDto.fromJson(
    Object? value, {
    required String description,
  }) {
    final json = _objectMap(value, description: description);
    return CustomerCarReferenceDto(
      id: _integer(json['id'], fieldName: '$description id'),
      name: _nonEmptyString(json['name'], fieldName: '$description name'),
    );
  }

  CustomerCarReference toEntity() {
    return CustomerCarReference(id: id, name: name);
  }
}

List<CustomerCarDto> customerCarListFromJson(Object? value) {
  if (value is! List) {
    throw const FormatException('Customer-car data is not a list.');
  }

  return value.map(CustomerCarDto.fromJson).toList(growable: false);
}

Map<String, Object?> _objectMap(Object? value, {required String description}) {
  if (value is! Map) {
    throw FormatException('$description is not a JSON object.');
  }

  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('$description has a non-string JSON key.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

int _integer(Object? value, {required String fieldName}) {
  if (value is! num ||
      value.isNaN ||
      value.isInfinite ||
      value != value.roundToDouble()) {
    throw FormatException('$fieldName is not an integer.');
  }
  return value.toInt();
}

String _nonEmptyString(Object? value, {required String fieldName}) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$fieldName is not a non-empty string.');
  }
  return value;
}

List<String> _stringList(Object? value, {required String fieldName}) {
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException('$fieldName is not a string list.');
  }
  return List.unmodifiable(value.cast<String>());
}

DateTime _dateTime(Object? value) {
  if (value is! String) {
    throw const FormatException('Customer car created_at is not a string.');
  }
  final result = DateTime.tryParse(value);
  if (result == null) {
    throw const FormatException('Customer car created_at is invalid.');
  }
  return result;
}
