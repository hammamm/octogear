/// The customer-selected filters for an active-store query.
class StorefrontFilters {
  const StorefrontFilters({this.query = '', this.cityId, this.companyId});

  const StorefrontFilters.empty() : this();

  final String query;
  final int? cityId;
  final int? companyId;

  bool get hasActiveFilters =>
      query.trim().isNotEmpty || cityId != null || companyId != null;

  int get activeFilterCount =>
      (query.trim().isNotEmpty ? 1 : 0) +
      (cityId != null ? 1 : 0) +
      (companyId != null ? 1 : 0);

  StorefrontFilters copyWith({
    String? query,
    int? cityId,
    int? companyId,
    bool clearCity = false,
    bool clearCompany = false,
  }) {
    return StorefrontFilters(
      query: query ?? this.query,
      cityId: clearCity ? null : cityId ?? this.cityId,
      companyId: clearCompany ? null : companyId ?? this.companyId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StorefrontFilters &&
        other.query == query &&
        other.cityId == cityId &&
        other.companyId == companyId;
  }

  @override
  int get hashCode => Object.hash(query, cityId, companyId);
}
