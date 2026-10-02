import '../../domain/entities/customer_car.dart';

class CustomerCarDto {
  const CustomerCarDto({
    required this.id,
    required this.manufacturingYear,
    this.transmissionType,
    required this.company,
    required this.carName,
    required this.color,
    required this.fuelType,
    required this.pictures,
    required this.createdAt,
  });

  final int id;
  final int manufacturingYear;
  final String? transmissionType;
  final CustomerCarReferenceDto company;
  final CustomerCarReferenceDto carName;
  final CustomerCarReferenceDto color;
  final CustomerCarReferenceDto fuelType;
  final List<CustomerCarPictureDto> pictures;
  final DateTime createdAt;

  factory CustomerCarDto.fromJson(Object? value) {
    final json = _objectMap(value, description: 'customer car');
    final id = _integer(json['id'], fieldName: 'customer car id');
    final manufacturingYear = _integer(
      json['manufacturing_year'],
      fieldName: 'customer car manufacturing_year',
    );
    final transmissionType = json['transmission_type'];
    if (transmissionType != null &&
        !const ['manual', 'automatic', 'unknown'].contains(transmissionType)) {
      throw const FormatException('Invalid customer car transmission_type.');
    }
    final createdAt = _dateTime(json['created_at']);

    return CustomerCarDto(
      id: id,
      manufacturingYear: manufacturingYear,
      transmissionType: transmissionType as String?,
      company: CustomerCarReferenceDto.fromJson(
        json['company'],
        description: 'customer car company',
      ),
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
      pictures: customerCarPictureListFromJson(json['pictures']),
      createdAt: createdAt,
    );
  }

  CustomerCar toEntity() {
    return CustomerCar(
      id: id,
      manufacturingYear: manufacturingYear,
      transmissionType: transmissionType,
      company: company.toEntity(),
      carName: carName.toEntity(),
      color: color.toEntity(),
      fuelType: fuelType.toEntity(),
      pictures: List.unmodifiable(
        pictures.map((picture) => picture.toEntity()),
      ),
      createdAt: createdAt,
    );
  }
}

/// Transport metadata for a private customer-car image.
///
/// The API deliberately returns a secure stream URL, never a storage path or
/// a file encoded inside the response JSON.
class CustomerCarPictureDto {
  const CustomerCarPictureDto({
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

  factory CustomerCarPictureDto.fromJson(Object? value) {
    final json = _objectMap(value, description: 'customer car picture');

    return CustomerCarPictureDto(
      id: _positiveInteger(json['id'], fieldName: 'customer car picture id'),
      url: _privateCustomerCarPictureUrl(json['url']),
      mimeType: _nonEmptyString(
        json['mime_type'],
        fieldName: 'customer car picture mime_type',
      ),
      sizeBytes: _nonNegativeInteger(
        json['size_bytes'],
        fieldName: 'customer car picture size_bytes',
      ),
      sortOrder: _nonNegativeInteger(
        json['sort_order'],
        fieldName: 'customer car picture sort_order',
      ),
    );
  }

  CustomerCarPicture toEntity() {
    return CustomerCarPicture(
      id: id,
      url: url,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      sortOrder: sortOrder,
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

List<CustomerCarPictureDto> customerCarPictureListFromJson(Object? value) {
  if (value is! List) {
    throw const FormatException('Customer-car pictures are not a list.');
  }

  return value.map(CustomerCarPictureDto.fromJson).toList(growable: false);
}

List<CustomerCarReferenceDto> customerCarReferenceListFromJson(Object? value) {
  if (value is! List) {
    throw const FormatException('Customer-car references are not a list.');
  }

  return value
      .map(
        (item) => CustomerCarReferenceDto.fromJson(
          item,
          description: 'customer car reference',
        ),
      )
      .toList(growable: false);
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

int _positiveInteger(Object? value, {required String fieldName}) {
  final result = _integer(value, fieldName: fieldName);
  if (result <= 0) throw FormatException('$fieldName is not positive.');
  return result;
}

int _nonNegativeInteger(Object? value, {required String fieldName}) {
  final result = _integer(value, fieldName: fieldName);
  if (result < 0) throw FormatException('$fieldName is negative.');
  return result;
}

String _nonEmptyString(Object? value, {required String fieldName}) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$fieldName is not a non-empty string.');
  }
  return value;
}

String _privateCustomerCarPictureUrl(Object? value) {
  final url = _nonEmptyString(value, fieldName: 'customer car picture url');
  final uri = Uri.tryParse(url);
  final isExpectedPath = RegExp(
    r'^/api/customer/customer-cars/[1-9]\d*/pictures/[1-9]\d*$',
  ).hasMatch(uri?.path ?? '');

  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      uri.hasQuery ||
      uri.hasFragment ||
      !isExpectedPath) {
    throw const FormatException(
      'Customer car picture URL is not private API media.',
    );
  }
  return url;
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
