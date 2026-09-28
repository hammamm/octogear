import '../../domain/entities/storefront_store_details.dart';
import 'marketplace_store_dto.dart';
import 'storefront_reference_dto.dart';

class StorefrontStoreDetailsDto {
  const StorefrontStoreDetailsDto({
    required this.id,
    required this.name,
    required this.nickname,
    required this.city,
    required this.companies,
    required this.pictures,
    required this.averageRating,
    required this.soldQuantity,
  });

  final int id;
  final String name;
  final String nickname;
  final StorefrontReferenceDto? city;
  final List<StorefrontReferenceDto> companies;
  final List<StorefrontStorePictureDto> pictures;
  final double? averageRating;
  final int soldQuantity;

  factory StorefrontStoreDetailsDto.fromJson(Object? value) {
    final json = storefrontObjectMap(value, 'store detail');
    final id = storefrontPositiveInteger(json['id'], 'store detail id');
    final picturesValue = json['pictures'];
    if (picturesValue is! List) {
      throw const FormatException('Store detail pictures are not a list.');
    }

    final name =
        storefrontOptionalString(json['name'], 'store detail name') ?? '';
    final nickname =
        storefrontOptionalString(json['nick_name'], 'store detail nickname') ??
        '';
    if (name.isEmpty && nickname.isEmpty) {
      throw const FormatException('Store detail has no display name.');
    }

    return StorefrontStoreDetailsDto(
      id: id,
      name: name,
      nickname: nickname,
      city: json['city'] == null
          ? null
          : StorefrontReferenceDto.fromJson(json['city']),
      companies: storefrontReferenceListFromJson(json['companies']),
      pictures: List.unmodifiable(
        picturesValue
            .map(
              (picture) =>
                  StorefrontStorePictureDto.fromJson(picture, storeId: id),
            )
            .toList(growable: false),
      ),
      averageRating: storefrontOptionalDouble(
        json['average_rating'],
        'store detail average_rating',
      ),
      soldQuantity: storefrontNonNegativeInteger(
        json['sold_quantity'],
        'store detail sold_quantity',
      ),
    );
  }

  StorefrontStoreDetails toEntity() => StorefrontStoreDetails(
    id: id,
    name: name,
    nickname: nickname,
    city: city?.toEntity(),
    companies: List.unmodifiable(
      companies.map((company) => company.toEntity()),
    ),
    pictures: List.unmodifiable(pictures.map((picture) => picture.toEntity())),
    averageRating: averageRating,
    soldQuantity: soldQuantity,
  );
}

class StorefrontStorePictureDto {
  const StorefrontStorePictureDto({
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

  factory StorefrontStorePictureDto.fromJson(
    Object? value, {
    required int storeId,
  }) {
    final json = storefrontObjectMap(value, 'store detail picture');
    final id = storefrontPositiveInteger(json['id'], 'store detail picture id');
    final url = storefrontOptionalString(
      json['url'],
      'store detail picture url',
    );
    if (url == null || !isTrustedStorePictureUrl(url, storeId, id)) {
      throw const FormatException('Store detail picture URL is not trusted.');
    }

    return StorefrontStorePictureDto(
      id: id,
      url: url,
      mimeType: storefrontOptionalString(
        json['mime_type'],
        'store detail picture mime_type',
      )!,
      sizeBytes: storefrontNonNegativeInteger(
        json['size_bytes'],
        'store detail picture size_bytes',
      ),
      sortOrder: storefrontNonNegativeInteger(
        json['sort_order'],
        'store detail picture sort_order',
      ),
    );
  }

  StorefrontStorePicture toEntity() => StorefrontStorePicture(
    id: id,
    url: url,
    mimeType: mimeType,
    sizeBytes: sizeBytes,
    sortOrder: sortOrder,
  );
}
