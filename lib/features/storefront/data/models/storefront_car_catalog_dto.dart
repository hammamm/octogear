import '../../domain/entities/storefront_car_catalog.dart';
import 'storefront_reference_dto.dart';
import 'storefront_store_car_dto.dart';

class StorefrontCarDetailsDto {
  const StorefrontCarDetailsDto({
    required this.car,
    required this.store,
    required this.company,
    required this.sections,
  });

  final StorefrontStoreCarDto car;
  final StorefrontReferenceDto store;
  final StorefrontReferenceDto? company;
  final List<StorefrontCarSectionDto> sections;

  factory StorefrontCarDetailsDto.fromJson(
    Object? value,
    StorefrontCarKey key,
  ) {
    final json = storefrontObjectMap(value, 'car detail');
    final car = StorefrontStoreCarDto.fromJson(json, storeId: key.storeId);
    final store = StorefrontReferenceDto.fromJson(json['store']);
    final sections = json['sections'];
    if (car.id != key.carId || store.id != key.storeId || sections is! List) {
      throw const FormatException('Invalid car detail context.');
    }
    return StorefrontCarDetailsDto(
      car: car,
      store: store,
      company: json['company'] == null
          ? null
          : StorefrontReferenceDto.fromJson(json['company']),
      sections: List.unmodifiable(
        sections.map(StorefrontCarSectionDto.fromJson),
      ),
    );
  }

  StorefrontCarDetails toEntity() => StorefrontCarDetails(
    car: car.toEntity(),
    store: store.toEntity(),
    company: company?.toEntity(),
    sections: List.unmodifiable(sections.map((section) => section.toEntity())),
  );
}

class StorefrontCarSectionDto {
  const StorefrontCarSectionDto(this.id, this.name, this.condition);
  final int id;
  final String name;
  final String condition;

  factory StorefrontCarSectionDto.fromJson(Object? value) {
    final json = storefrontObjectMap(value, 'car section');
    return StorefrontCarSectionDto(
      storefrontPositiveInteger(json['section_id'], 'section_id'),
      storefrontOptionalString(json['name'], 'section name') ?? '',
      storefrontOptionalString(json['condition'], 'section condition') ??
          'unknown',
    );
  }

  StorefrontCarSection toEntity() => StorefrontCarSection(
    id: id,
    name: name,
    condition: switch (condition) {
      'okay' => StorefrontSectionCondition.okay,
      'damaged' => StorefrontSectionCondition.damaged,
      _ => StorefrontSectionCondition.unknown,
    },
  );
}

class StorefrontCarComponentDto {
  const StorefrontCarComponentDto({
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
  final StorefrontReferenceDto component;
  final StorefrontReferenceDto? section;
  final int priceMinor;
  final String currency;
  final int priceScale;
  final int stockQuantity;
  final String? partNumber;
  final String? description;
  final int? warrantyMonths;

  factory StorefrontCarComponentDto.fromJson(Object? value) {
    final json = storefrontObjectMap(value, 'car component');
    // The API explicitly describes the existing SAR/halala catalog. Fail
    // safely instead of silently guessing money units from a changed schema.
    if (json['currency'] != 'SAR' || json['price_scale'] != 100) {
      throw const FormatException('Unsupported catalog price units.');
    }
    return StorefrontCarComponentDto(
      id: storefrontPositiveInteger(json['id'], 'component inventory id'),
      component: StorefrontReferenceDto.fromJson(json['component']),
      section: json['section'] == null
          ? null
          : StorefrontReferenceDto.fromJson(json['section']),
      priceMinor: storefrontNonNegativeInteger(json['price'], 'price'),
      currency: 'SAR',
      priceScale: 100,
      stockQuantity: storefrontNonNegativeInteger(
        json['stock_quantity'],
        'stock_quantity',
      ),
      partNumber: _optionalText(json['part_number']),
      description: _optionalText(json['description']),
      warrantyMonths: json['warranty_months'] == null
          ? null
          : storefrontNonNegativeInteger(
              json['warranty_months'],
              'warranty_months',
            ),
    );
  }

  StorefrontCarComponent toEntity() => StorefrontCarComponent(
    id: id,
    component: component.toEntity(),
    section: section?.toEntity(),
    priceMinor: priceMinor,
    currency: currency,
    priceScale: priceScale,
    stockQuantity: stockQuantity,
    partNumber: partNumber,
    description: description,
    warrantyMonths: warrantyMonths,
  );
}

String? _optionalText(Object? value) {
  if (value == null) return null;
  if (value is! String) throw const FormatException('Expected text.');
  return value.trim().isEmpty ? null : value.trim();
}
