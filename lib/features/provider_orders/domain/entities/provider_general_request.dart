class ProviderGeneralRequest {
  const ProviderGeneralRequest({
    required this.id,
    required this.createdAt,
    required this.status,
    this.partName,
    this.cityId,
    this.cityName,
    this.carName,
    this.companyName,
    this.year,
    this.notes,
    this.transmission,
    this.color,
    this.fuel,
    this.imagePaths = const [],
  });
  final int id;
  final DateTime createdAt;
  final String status;
  final int? cityId, year;
  final String? partName,
      cityName,
      carName,
      companyName,
      notes,
      transmission,
      color,
      fuel;
  final List<String> imagePaths;
}

class ProviderGeneralRequestsPage {
  const ProviderGeneralRequestsPage({
    required this.items,
    required this.page,
    required this.lastPage,
    required this.total,
  });
  final List<ProviderGeneralRequest> items;
  final int page, lastPage, total;
  bool get hasMore => page < lastPage;
}
