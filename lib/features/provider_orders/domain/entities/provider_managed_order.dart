enum ProviderOrderKind { direct, paid }

typedef ProviderOrderQuery = ({ProviderOrderKind kind, String? status});
typedef ProviderOrderKey = ({ProviderOrderKind kind, int id});

class ProviderManagedOrder {
  const ProviderManagedOrder({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.storeName,
    required this.canAccept,
    required this.canReject,
    this.partName,
    this.partNumber,
    this.city,
    this.customerName,
    this.description,
    this.carName,
    this.companyName,
    this.year,
    this.color,
    this.fuel,
    this.transmission,
    this.quantity,
    this.requestedUnitPrice,
    this.unitPrice,
    this.total,
    this.commission,
    this.net,
    this.acceptedOfferId,
    this.imagePaths = const [],
  });
  final int id;
  final String type, status, storeName;
  final DateTime createdAt;
  final bool canAccept, canReject;
  final String? partName,
      partNumber,
      city,
      customerName,
      description,
      carName,
      companyName,
      color,
      fuel,
      transmission;
  final int? year,
      quantity,
      requestedUnitPrice,
      unitPrice,
      total,
      commission,
      net,
      acceptedOfferId;
  final List<String> imagePaths;
  bool get isPaid => status == 'paid' || status == 'completed';
}

class ProviderManagedOrdersPage {
  const ProviderManagedOrdersPage(
    this.items,
    this.page,
    this.lastPage,
    this.total,
  );
  final List<ProviderManagedOrder> items;
  final int page, lastPage, total;
  bool get hasMore => page < lastPage;
}
