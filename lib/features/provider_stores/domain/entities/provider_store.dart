enum ProviderStoreStatus { active, inactive, unknown }

/// An owned business, separate from personal customer data.
class ProviderStore {
  const ProviderStore({
    required this.id,
    required this.name,
    required this.status,
    required this.brands,
    this.mobile,
    this.city,
    this.cityId,
    this.location,
  });

  final int id;
  final String name;
  final ProviderStoreStatus status;
  final String? mobile;
  final String? city;
  final int? cityId;
  final String? location;
  final List<String> brands;
}
