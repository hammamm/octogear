import '../../domain/entities/marketplace_store.dart';
import 'storefront_reference_dto.dart';

class MarketplaceStoreDto {
  const MarketplaceStoreDto({
    required this.id,
    required this.name,
    required this.nickname,
    required this.city,
    required this.primaryPictureUrl,
    required this.averageRating,
  });

  final int id;
  final String name;
  final String nickname;
  final StorefrontReferenceDto? city;
  final String? primaryPictureUrl;
  final double? averageRating;

  factory MarketplaceStoreDto.fromJson(Object? value) {
    final json = storefrontObjectMap(value, 'marketplace store');
    final id = storefrontPositiveInteger(json['id'], 'marketplace store id');
    final pictures = json['pictures'];
    if (pictures is! List) {
      throw const FormatException('Marketplace store pictures are not a list.');
    }

    return MarketplaceStoreDto(
      id: id,
      name:
          storefrontOptionalString(json['name'], 'marketplace store name') ??
          '',
      nickname:
          storefrontOptionalString(
            json['nick_name'],
            'marketplace store nickname',
          ) ??
          '',
      city: json['city'] == null
          ? null
          : StorefrontReferenceDto.fromJson(json['city']),
      primaryPictureUrl: pictures.isEmpty
          ? null
          : StorefrontPictureDto.fromJson(pictures.first, storeId: id).url,
      averageRating: storefrontOptionalDouble(
        json['average_rating'],
        'marketplace store average_rating',
      ),
    );
  }

  MarketplaceStore toEntity() {
    if (name.isEmpty && nickname.isEmpty) {
      throw const FormatException('Marketplace store has no display name.');
    }
    return MarketplaceStore(
      id: id,
      name: name,
      nickname: nickname,
      city: city?.toEntity(),
      primaryPictureUrl: primaryPictureUrl,
      averageRating: averageRating,
    );
  }
}

class StorefrontPictureDto {
  const StorefrontPictureDto({required this.url});

  final String url;

  factory StorefrontPictureDto.fromJson(Object? value, {required int storeId}) {
    final json = storefrontObjectMap(value, 'marketplace store picture');
    final pictureId = storefrontPositiveInteger(
      json['id'],
      'marketplace store picture id',
    );
    final url = storefrontOptionalString(
      json['url'],
      'marketplace store picture url',
    );
    if (url == null || !isTrustedStorePictureUrl(url, storeId, pictureId)) {
      throw const FormatException(
        'Marketplace store picture URL is not trusted API media.',
      );
    }
    return StorefrontPictureDto(url: url);
  }
}

List<MarketplaceStoreDto> marketplaceStoreListFromJson(Object? value) {
  if (value is! List) {
    throw const FormatException('Marketplace store data is not a list.');
  }
  return value.map(MarketplaceStoreDto.fromJson).toList(growable: false);
}

/// Verifies the exact documented path before authenticated Flutter image
/// loading can resolve a URL or attach a bearer header to it.
bool isTrustedStorePictureUrl(String value, int storeId, int pictureId) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      !uri.hasScheme &&
      !uri.hasAuthority &&
      !uri.hasQuery &&
      !uri.hasFragment &&
      uri.path == '/api/media/stores/$storeId/pictures/$pictureId';
}
