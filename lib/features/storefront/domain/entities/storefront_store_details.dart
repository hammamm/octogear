import 'marketplace_store.dart';

/// Public, customer-safe representation of one active marketplace store.
///
/// Provider contact, management, and registration fields intentionally do not
/// exist here, so a customer screen cannot accidentally render them.
class StorefrontStoreDetails {
  const StorefrontStoreDetails({
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
  final StorefrontReference? city;
  final List<StorefrontReference> companies;
  final List<StorefrontStorePicture> pictures;
  final double? averageRating;
  final int soldQuantity;

  String get displayName => nickname.isEmpty ? name : nickname;
}

class StorefrontStorePicture {
  const StorefrontStorePicture({
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
