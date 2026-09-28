import 'marketplace_store.dart';

/// Localized reference values used to narrow the storefront list.
class StorefrontFilterOptions {
  const StorefrontFilterOptions({
    required this.cities,
    required this.companies,
  });

  final List<StorefrontReference> cities;
  final List<StorefrontReference> companies;
}
