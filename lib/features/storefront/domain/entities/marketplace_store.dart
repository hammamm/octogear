/// Customer-safe summary of one active marketplace store.
///
/// Contact, commercial-registration, and management-only fields deliberately
/// do not belong to this browsing entity.
class MarketplaceStore {
  const MarketplaceStore({
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
  final StorefrontReference? city;
  final String? primaryPictureUrl;
  final double? averageRating;

  String get displayName => nickname.isEmpty ? name : nickname;
}

/// A localized, ID-backed option used by storefront filters.
class StorefrontReference {
  const StorefrontReference({required this.id, required this.name});

  final int id;
  final String name;
}
