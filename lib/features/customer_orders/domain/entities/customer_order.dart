enum CustomerOrderType { specific, general }

enum CustomerOrderFilter { all, specific, general }

enum CustomerOrderStatus {
  pending,
  awaitingPayment,
  paid,
  completed,
  cancelled,
  rejected,
  unknown,
}

enum CustomerOfferStatus { pending, accepted, rejected, notSelected, unknown }

class OrderStore {
  const OrderStore({
    required this.id,
    required this.name,
    this.employeeName,
    this.locationUrl,
  });
  final int id;
  final String? name;
  final String? employeeName, locationUrl;
}

class OrderPaymentSummary {
  const OrderPaymentSummary({
    required this.id,
    required this.amount,
    required this.status,
    required this.method,
    required this.createdAt,
  });
  final int id, amount;
  final String status, method;
  final DateTime createdAt;
}

class CustomerOrderOffer {
  const CustomerOrderOffer({
    required this.id,
    required this.totalPrice,
    required this.status,
    this.store,
    this.notes,
    this.rejectionReason,
    this.imagePaths = const [],
  });
  final int id;
  final int totalPrice;
  final CustomerOfferStatus status;
  final OrderStore? store;
  final String? notes;
  final String? rejectionReason;
  final List<String> imagePaths;
}

class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.type,
    required this.status,
    this.quantity,
    required this.createdAt,
    required this.offersCount,
    required this.offers,
    this.canEdit = false,
    this.canDelete = false,
    this.canCancel = false,
    this.canConfirmReceived = false,
    this.payment,
    this.editToken,
    this.componentId,
    this.vehicleIds = const OrderVehicleIds(),
    this.partName,
    this.partNumber,
    this.carName,
    this.companyName,
    this.transmissionType,
    this.colorName,
    this.fuelTypeName,
    this.acceptedOfferId,
    this.manufacturingYear,
    this.store,
    this.acceptedStore,
    this.listedUnitPrice,
    this.requestedUnitPrice,
    this.offeredPrice,
    this.paidAmount,
    this.notes,
    this.imagePaths = const [],
  });
  final int id;
  final bool canEdit, canDelete;
  final bool canCancel, canConfirmReceived;
  final OrderPaymentSummary? payment;
  final String? editToken;
  final int? componentId;
  final OrderVehicleIds vehicleIds;
  final CustomerOrderType type;
  final CustomerOrderStatus status;
  final int? quantity;
  final DateTime createdAt;
  final String? partName,
      partNumber,
      carName,
      companyName,
      transmissionType,
      colorName,
      fuelTypeName,
      notes;
  final List<String> imagePaths;
  final int? acceptedOfferId;
  final int? manufacturingYear,
      listedUnitPrice,
      requestedUnitPrice,
      offeredPrice,
      paidAmount;
  final OrderStore? store, acceptedStore;
  final int offersCount;
  final List<CustomerOrderOffer> offers;
  bool get isGeneral => type == CustomerOrderType.general;
  bool get hasSelectedOffer => acceptedOfferId != null;
  OrderStore? get displayStore => isGeneral ? acceptedStore : store;
  // Payment records are historical truth. Otherwise these are explicitly
  // labeled listing/selected-offer amounts, never an invented payment total.
  int? get displayTotal =>
      paidAmount ??
      (isGeneral
          ? offeredPrice
          : (requestedUnitPrice ?? listedUnitPrice) == null
          ? null
          : (requestedUnitPrice ?? listedUnitPrice)! * (quantity ?? 1));
}

class CustomerOrdersPage {
  const CustomerOrdersPage({
    required this.orders,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
  final List<CustomerOrder> orders;
  final int currentPage, lastPage, total;
  bool get hasMore => currentPage < lastPage;
}

class OrderVehicleIds {
  const OrderVehicleIds({
    this.carNameId,
    this.companyId,
    this.colorId,
    this.fuelTypeId,
  });
  final int? carNameId, companyId, colorId, fuelTypeId;
}

bool canRespondToOffer(CustomerOrder order, CustomerOrderOffer offer) =>
    order.isGeneral &&
    order.status == CustomerOrderStatus.pending &&
    !order.hasSelectedOffer &&
    offer.status == CustomerOfferStatus.pending;
