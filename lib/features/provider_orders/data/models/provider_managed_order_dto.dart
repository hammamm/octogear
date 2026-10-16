import '../../domain/entities/provider_managed_order.dart';

class ProviderManagedOrderDto {
  const ProviderManagedOrderDto._(this.value);
  final ProviderManagedOrder value;
  ProviderManagedOrder toEntity() => value;

  factory ProviderManagedOrderDto.fromJson(Object? value) {
    final json = _map(value);
    final id = _integer(json['id'], positive: true)!;
    final type = _text(json['order_type']);
    final status = _text(json['status']);
    final date = DateTime.tryParse(_text(json['created_at']) ?? '');
    if (!['general', 'specific'].contains(type) ||
        status == null ||
        date == null ||
        json['currency'] != 'SAR' ||
        json['price_scale'] != 100) {
      throw const FormatException('Invalid provider order.');
    }
    final store = json['store'] == null ? null : _map(json['store']);
    final vehicle = json['vehicle_details'] == null
        ? null
        : _map(json['vehicle_details']);
    final city = json['city'] == null ? null : _map(json['city']);
    final customer = json['sold_to'] == null ? null : _map(json['sold_to']);
    final images = json['images'] ?? const [];
    if (images is! List) throw const FormatException('Invalid order images.');
    final quantity = _integer(json['quantity'], positive: true, optional: true);
    final requested = _integer(json['requested_unit_price'], optional: true);
    final total = _integer(json['total_amount'], optional: true);
    final commission = _integer(json['commission'], optional: true);
    final net = _integer(json['net_amount'], optional: true);
    if ((commission != null || net != null) &&
        (total == null ||
            commission == null ||
            net == null ||
            commission + net != total)) {
      throw const FormatException('Invalid order amounts.');
    }
    final pending = type == 'specific' && status == 'pending';
    if (pending &&
        json['can_accept'] == true &&
        (total == null ||
            quantity == null ||
            requested == null ||
            total != requested * quantity)) {
      throw const FormatException('Invalid acceptance total.');
    }
    return ProviderManagedOrderDto._(
      ProviderManagedOrder(
        id: id,
        type: type!,
        status: status,
        createdAt: date,
        storeName: _text(store?['name']) ?? '',
        partName: _text(json['part_name']),
        partNumber: _text(json['part_number']),
        city: _text(city?['name']),
        customerName: _text(customer?['name']),
        description: _text(json['description']),
        carName: _text(vehicle?['car_name']),
        companyName: _text(vehicle?['company_name']),
        year: _integer(
          vehicle?['manufacturing_year'],
          positive: true,
          optional: true,
        ),
        color: _text(vehicle?['color_name']),
        fuel: _text(vehicle?['fuel_type_name']),
        transmission: _text(vehicle?['transmission_type']),
        quantity: quantity,
        requestedUnitPrice: requested,
        unitPrice: _integer(json['unit_price'], optional: true),
        total: total,
        commission: commission,
        net: net,
        acceptedOfferId: _integer(
          json['accepted_offer_id'],
          positive: true,
          optional: true,
        ),
        canAccept:
            pending &&
            json['can_accept'] == true &&
            (requested ?? 0) > 0 &&
            (quantity ?? 0) > 0,
        canReject: pending && json['can_reject'] == true,
        imagePaths: List.unmodifiable(
          images.map((image) {
            final path = _map(image)['url'];
            if (path is! String ||
                !RegExp(
                  '^/api/media/orders/$id/images/[1-9][0-9]*\$',
                ).hasMatch(path)) {
              throw const FormatException('Invalid private order image.');
            }
            return path;
          }),
        ),
      ),
    );
  }
}

class ProviderManagedOrdersPageDto {
  const ProviderManagedOrdersPageDto(
    this.items,
    this.page,
    this.lastPage,
    this.total,
  );
  final List<ProviderManagedOrderDto> items;
  final int page, lastPage, total;
  ProviderManagedOrdersPage toEntity() => ProviderManagedOrdersPage(
    List.unmodifiable(items.map((item) => item.toEntity())),
    page,
    lastPage,
    total,
  );
}

Map<String, dynamic> _map(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Expected order object.');
  }
  return value;
}

String? _text(Object? value) {
  if (value == null) return null;
  if (value is! String) throw const FormatException('Invalid order text.');
  return value.trim().isEmpty ? null : value.trim();
}

int? _integer(Object? value, {bool positive = false, bool optional = false}) {
  if (optional && value == null) return null;
  if (value is! int || value < (positive ? 1 : 0)) {
    throw const FormatException('Invalid order integer.');
  }
  return value;
}
