import '../../domain/entities/marketplace_store.dart';

class StorefrontReferenceDto {
  const StorefrontReferenceDto({required this.id, required this.name});

  final int id;
  final String name;

  factory StorefrontReferenceDto.fromJson(Object? value) {
    final json = _objectMap(value, 'storefront reference');
    return StorefrontReferenceDto(
      id: _positiveInteger(json['id'], 'storefront reference id'),
      name: _nonEmptyString(json['name'], 'storefront reference name'),
    );
  }

  StorefrontReference toEntity() => StorefrontReference(id: id, name: name);
}

List<StorefrontReferenceDto> storefrontReferenceListFromJson(Object? value) {
  if (value is! List) {
    throw const FormatException('Storefront reference data is not a list.');
  }
  return value.map(StorefrontReferenceDto.fromJson).toList(growable: false);
}

Map<String, Object?> storefrontObjectMap(Object? value, String description) =>
    _objectMap(value, description);

int storefrontPositiveInteger(Object? value, String fieldName) =>
    _positiveInteger(value, fieldName);

int storefrontNonNegativeInteger(Object? value, String fieldName) {
  if (value is! num ||
      value.isNaN ||
      value.isInfinite ||
      value != value.roundToDouble() ||
      value < 0) {
    throw FormatException('$fieldName is not a non-negative integer.');
  }
  return value.toInt();
}

String? storefrontOptionalString(Object? value, String fieldName) {
  if (value == null) return null;
  return _nonEmptyString(value, fieldName);
}

double? storefrontOptionalDouble(Object? value, String fieldName) {
  if (value == null) return null;
  if (value is! num || value.isNaN || value.isInfinite) {
    throw FormatException('$fieldName is not a number.');
  }
  return value.toDouble();
}

Map<String, Object?> _objectMap(Object? value, String description) {
  if (value is! Map) {
    throw FormatException('$description is not a JSON object.');
  }
  final json = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('$description has a non-string JSON key.');
    }
    json[entry.key as String] = entry.value;
  }
  return json;
}

int _positiveInteger(Object? value, String fieldName) {
  if (value is! num ||
      value.isNaN ||
      value.isInfinite ||
      value != value.roundToDouble() ||
      value <= 0) {
    throw FormatException('$fieldName is not a positive integer.');
  }
  return value.toInt();
}

String _nonEmptyString(Object? value, String fieldName) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$fieldName is not a non-empty string.');
  }
  return value;
}
