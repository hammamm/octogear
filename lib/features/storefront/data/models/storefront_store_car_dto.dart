import '../../domain/entities/storefront_store_car.dart';
import 'storefront_reference_dto.dart';

class StorefrontStoreCarDto {
  const StorefrontStoreCarDto({
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
  final StorefrontReferenceDto carName;
  final StorefrontReferenceDto color;
  final StorefrontReferenceDto fuelType;
  final int componentsCount;
  final List<StorefrontStoreCarPictureDto> pictures;

  factory StorefrontStoreCarDto.fromJson(
    Object? value, {
    required int storeId,
  }) {
    final json = storefrontObjectMap(value, 'store inventory car');
    final id = storefrontPositiveInteger(json['id'], 'store inventory car id');
    final picturesValue = json['pictures'];
    if (picturesValue is! List) {
      throw const FormatException(
        'Store inventory car pictures are not a list.',
      );
    }

    return StorefrontStoreCarDto(
      id: id,
      manufacturingYear: storefrontPositiveInteger(
        json['manufacturing_year'],
        'store inventory manufacturing_year',
      ),
      carName: StorefrontReferenceDto.fromJson(json['car_name']),
      color: StorefrontReferenceDto.fromJson(json['color']),
      fuelType: StorefrontReferenceDto.fromJson(json['fuel_type']),
      componentsCount: storefrontNonNegativeInteger(
        json['components_count'],
        'store inventory components_count',
      ),
      pictures: List.unmodifiable(
        picturesValue
            .map(
              (picture) => StorefrontStoreCarPictureDto.fromJson(
                picture,
                storeId: storeId,
                carId: id,
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  StorefrontStoreCar toEntity() => StorefrontStoreCar(
    id: id,
    manufacturingYear: manufacturingYear,
    carName: carName.toEntity(),
    color: color.toEntity(),
    fuelType: fuelType.toEntity(),
    componentsCount: componentsCount,
    pictures: List.unmodifiable(pictures.map((picture) => picture.toEntity())),
  );
}

List<StorefrontStoreCarDto> storefrontStoreCarListFromJson(
  Object? value, {
  required int storeId,
}) {
  if (value is! List) {
    throw const FormatException('Store inventory data is not a list.');
  }
  return List.unmodifiable(
    value
        .map((car) => StorefrontStoreCarDto.fromJson(car, storeId: storeId))
        .toList(growable: false),
  );
}

class StorefrontStoreCarPictureDto {
  const StorefrontStoreCarPictureDto({
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

  factory StorefrontStoreCarPictureDto.fromJson(
    Object? value, {
    required int storeId,
    required int carId,
  }) {
    final json = storefrontObjectMap(value, 'store inventory car picture');
    final id = storefrontPositiveInteger(
      json['id'],
      'store inventory car picture id',
    );
    final url = storefrontOptionalString(
      json['url'],
      'store inventory car picture url',
    );
    if (url == null || !_isTrustedStoreCarPictureUrl(url, storeId, carId, id)) {
      throw const FormatException(
        'Store inventory car picture URL is not trusted.',
      );
    }

    return StorefrontStoreCarPictureDto(
      id: id,
      url: url,
      mimeType: storefrontOptionalString(
        json['mime_type'],
        'store inventory car picture mime_type',
      )!,
      sizeBytes: storefrontNonNegativeInteger(
        json['size_bytes'],
        'store inventory car picture size_bytes',
      ),
      sortOrder: storefrontNonNegativeInteger(
        json['sort_order'],
        'store inventory car picture sort_order',
      ),
    );
  }

  StorefrontStoreCarPicture toEntity() => StorefrontStoreCarPicture(
    id: id,
    url: url,
    mimeType: mimeType,
    sizeBytes: sizeBytes,
    sortOrder: sortOrder,
  );
}

bool _isTrustedStoreCarPictureUrl(
  String value,
  int storeId,
  int carId,
  int pictureId,
) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      !uri.hasScheme &&
      !uri.hasAuthority &&
      !uri.hasQuery &&
      !uri.hasFragment &&
      uri.path == '/api/media/stores/$storeId/cars/$carId/pictures/$pictureId';
}
