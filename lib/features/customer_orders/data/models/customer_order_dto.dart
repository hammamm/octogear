import '../../domain/entities/customer_order.dart';

class CustomerOrdersPageDto {
  const CustomerOrdersPageDto({
    required this.orders,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
  final List<CustomerOrderDto> orders;
  final int currentPage, lastPage, total;
  CustomerOrdersPage toEntity() => CustomerOrdersPage(
    orders: List.unmodifiable(orders.map((order) => order.toEntity())),
    currentPage: currentPage,
    lastPage: lastPage,
    total: total,
  );
}

class CustomerOrderDto {
  const CustomerOrderDto._(this.value);
  final CustomerOrder value;
  CustomerOrder toEntity() => value;

  factory CustomerOrderDto.fromJson(Object? value) {
    final json = _map(value);
    final id = _int(json['id'], positive: true);
    final type = switch (json['order_type']) {
      'general' => CustomerOrderType.general,
      'specific' => CustomerOrderType.specific,
      _ => throw const FormatException('Unsupported order type.'),
    };
    if (json['currency'] != 'SAR' || json['price_scale'] != 100) {
      throw const FormatException('Unsupported money contract.');
    }
    final createdAt = json['created_at'] is String
        ? DateTime.tryParse(json['created_at'] as String)
        : null;
    if (createdAt == null) throw const FormatException('Invalid order date.');
    final part = json['store_car_component'] == null
        ? null
        : _map(json['store_car_component']);
    final vehicle = json['vehicle_details'] == null
        ? null
        : _map(json['vehicle_details']);
    final offers = json['offers'];
    if (offers != null && offers is! List) {
      throw const FormatException('Invalid offers.');
    }
    return CustomerOrderDto._(
      CustomerOrder(
        id: id,
        type: type,
        canEdit: json['can_edit'] == true && json['edit_token'] is String,
        canDelete: json['can_delete'] == true && json['edit_token'] is String,
        editToken: _text(json['edit_token']),
        canCancel:
            json['can_cancel'] == true &&
            ['pending', 'awaiting_payment'].contains(json['status']),
        canConfirmReceived:
            json['can_confirm_received'] == true && json['status'] == 'paid',
        payment: _payment(json['payment_summary'], id),
        componentId: _nullableInt(json['component_id']),
        vehicleIds: OrderVehicleIds(
          carNameId: _nullableInt(vehicle?['car_name_id']),
          companyId: _nullableInt(vehicle?['car_company_id']),
          colorId: _nullableInt(vehicle?['color_id']),
          fuelTypeId: _nullableInt(vehicle?['fuel_type']),
        ),
        quantity: type == CustomerOrderType.specific
            ? _int(json['quantity'], positive: true)
            : null,
        createdAt: createdAt,
        status: CustomerOrderStatus.values.firstWhere(
          (status) =>
              (status == CustomerOrderStatus.awaitingPayment
                  ? 'awaiting_payment'
                  : status.name) ==
              json['status'],
          orElse: () => CustomerOrderStatus.unknown,
        ),
        partName: _text(json['part_name'] ?? json['component_name']),
        partNumber: _text(part?['part_number']),
        carName: _text(vehicle?['car_name'] ?? json['car_name']),
        companyName: _text(vehicle?['company_name']),
        transmissionType: _text(vehicle?['transmission_type']),
        colorName: _text(vehicle?['color_name']),
        fuelTypeName: _text(vehicle?['fuel_type_name']),
        manufacturingYear: _nullableInt(
          vehicle?['manufacturing_year'] ?? json['manufacturing_year'],
        ),
        acceptedOfferId: json['accepted_offer_id'] == null
            ? null
            : _int(json['accepted_offer_id'], positive: true),
        listedUnitPrice: _nullableInt(part?['price']),
        offeredPrice: _nullableInt(json['offered_price']),
        paidAmount: _nullableInt(json['paid_amount']),
        store: _store(part?['store']),
        acceptedStore: _store(json['accepted_store']),
        requestedUnitPrice: _nullableInt(json['requested_unit_price']),
        notes: _text(json['description'] ?? json['notes']),
        imagePaths: _images(json['images'], 'orders', id),
        offersCount: _int(json['offers_count']),
        offers: List.unmodifiable(
          (offers as List? ?? []).map((value) {
            final offer = _map(value);
            final offerId = _int(offer['id'], positive: true);
            return CustomerOrderOffer(
              id: offerId,
              imagePaths: _images(offer['images'], 'offers', offerId),
              totalPrice: _int(offer['price']),
              status: CustomerOfferStatus.values.firstWhere(
                (status) =>
                    (status == CustomerOfferStatus.notSelected
                        ? 'not_selected'
                        : status.name) ==
                    offer['status'],
                orElse: () => CustomerOfferStatus.unknown,
              ),
              store: _store(offer['store']),
              notes: _text(offer['notes']),
              rejectionReason: _text(offer['rejection_reason']),
            );
          }),
        ),
      ),
    );
  }
}

Map _map(Object? value) {
  if (value is! Map) throw const FormatException('Expected object.');
  return value;
}

int _int(Object? value, {bool positive = false}) {
  if (value is! int || value < (positive ? 1 : 0)) {
    throw const FormatException('Invalid integer.');
  }
  return value;
}

int? _nullableInt(Object? value) => value == null ? null : _int(value);
String? _text(Object? value) {
  if (value == null) return null;
  if (value is! String) throw const FormatException('Invalid text.');
  return value.trim().isEmpty ? null : value.trim();
}

OrderStore? _store(Object? value) {
  if (value == null) return null;
  final store = _map(value);
  if (store['id'] == null) {
    return null; // A retained order may outlive its store.
  }
  return OrderStore(
    id: _int(store['id'], positive: true),
    name: _text(store['name']),
    employeeName: _text(store['employee_name']),
    locationUrl: _text(store['url_location']),
  );
}

OrderPaymentSummary? _payment(Object? value, int orderId) {
  if (value == null) return null;
  final json = _map(value);
  final date = DateTime.tryParse(_text(json['created_at']) ?? '');
  if (json['order_id'] != orderId || date == null) {
    throw const FormatException('Invalid payment summary.');
  }
  final status = _text(json['payment_status']);
  return OrderPaymentSummary(
    id: _int(json['id'], positive: true),
    amount: _int(json['amount']),
    status: ['pending', 'paid', 'failed', 'refunded'].contains(status)
        ? status!
        : 'unknown',
    method: _text(json['payment_method']) ?? 'unknown',
    createdAt: date,
  );
}

List<String> _images(Object? value, String kind, int ownerId) {
  if (value is! List) throw const FormatException('Expected image list.');
  return List.unmodifiable(
    value.map((item) {
      final image = _map(item);
      final imageId = _int(image['id'], positive: true);
      final path = '/api/media/$kind/$ownerId/images/$imageId';
      if (image['url'] != path) {
        throw const FormatException('Unsafe image path.');
      }
      return path;
    }),
  );
}
