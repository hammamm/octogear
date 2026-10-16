enum ProviderDashboardPeriod {
  today,
  week,
  month;

  String get apiValue => name;
}

enum ProviderDashboardSection {
  pendingDirect('pending_direct'),
  awaitingPayment('awaiting_payment'),
  paid('paid'),
  recent('recent');

  const ProviderDashboardSection(this.apiValue);
  final String apiValue;
}

typedef ProviderDashboardQuery = ({
  int? storeId,
  ProviderDashboardPeriod period,
});
typedef ProviderDashboardActivityQuery = ({
  int? storeId,
  ProviderDashboardSection section,
});

class ProviderDashboardStore {
  const ProviderDashboardStore({required this.id, required this.name});
  final int id;
  final String name;
}

class ProviderDashboardCounts {
  const ProviderDashboardCounts({
    required this.pendingDirectRequests,
    required this.pendingOffers,
    required this.acceptedOffers,
    required this.paidOrders,
  });
  final int pendingDirectRequests, pendingOffers, acceptedOffers, paidOrders;
}

class ProviderDashboardSales {
  const ProviderDashboardSales({
    required this.amount,
    required this.count,
    required this.currency,
    required this.priceScale,
    required this.from,
    required this.to,
    required this.timezone,
  });
  final int amount, count, priceScale;
  final String currency, timezone;
  final DateTime from, to;
}

class ProviderDashboardOrder {
  const ProviderDashboardOrder({
    required this.id,
    required this.type,
    required this.status,
    required this.partName,
    required this.store,
    required this.createdAt,
    required this.updatedAt,
    required this.canChat,
    this.customerName,
    this.quantity,
    this.totalAmount,
    this.acceptedOfferId,
  });
  final int id;
  final String type, status;
  final String? partName;
  final ProviderDashboardStore store;
  final String? customerName;
  final int? quantity, totalAmount, acceptedOfferId;
  final DateTime createdAt, updatedAt;
  final bool canChat;
}

class ProviderDashboardOrderGroup {
  const ProviderDashboardOrderGroup({required this.items, required this.total});
  final List<ProviderDashboardOrder> items;
  final int total;
}

class ProviderDashboard {
  const ProviderDashboard({
    required this.stores,
    required this.selectedStoreId,
    required this.period,
    required this.generatedAt,
    required this.counts,
    required this.sales,
    required this.pendingDirect,
    required this.awaitingPayment,
    required this.paid,
    required this.recentOrders,
  });
  final List<ProviderDashboardStore> stores;
  final int? selectedStoreId;
  final ProviderDashboardPeriod period;
  final DateTime generatedAt;
  final ProviderDashboardCounts counts;
  final ProviderDashboardSales sales;
  final ProviderDashboardOrderGroup pendingDirect,
      awaitingPayment,
      paid,
      recentOrders;
}

class ProviderDashboardActivityPage {
  const ProviderDashboardActivityPage({
    required this.items,
    required this.page,
    required this.lastPage,
    required this.total,
  });
  final List<ProviderDashboardOrder> items;
  final int page, lastPage, total;
  bool get hasMore => page < lastPage;
}
