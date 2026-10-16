import 'package:octogear/features/provider_orders/domain/entities/provider_managed_order.dart';
import 'package:octogear/features/provider_orders/domain/repositories/provider_managed_orders_repository.dart';

ProviderManagedOrder testManagedOrder({
  int id = 31,
  String status = 'pending',
  String type = 'specific',
  bool? canAccept,
}) => ProviderManagedOrder(
  id: id,
  type: type,
  status: status,
  createdAt: DateTime.utc(2026, 10, 15),
  storeName: 'Al Faris Parts',
  partName: 'Front headlight',
  partNumber: 'HL-100',
  city: 'Riyadh',
  companyName: 'Toyota',
  carName: 'Camry',
  year: 2020,
  quantity: type == 'specific' ? 2 : null,
  requestedUnitPrice: type == 'specific' ? 12345 : null,
  unitPrice: type == 'specific' ? 12345 : null,
  total: 24690,
  description: 'Please confirm availability.',
  canAccept: canAccept ?? (type == 'specific' && status == 'pending'),
  canReject: type == 'specific' && status == 'pending',
  commission: ['paid', 'completed'].contains(status) ? 1235 : null,
  net: ['paid', 'completed'].contains(status) ? 23455 : null,
  customerName: ['paid', 'completed'].contains(status) ? 'Customer' : null,
);

Map<String, dynamic> managedOrderJson({
  String status = 'pending',
  int id = 31,
}) => {
  'id': id,
  'order_type': 'specific',
  'status': status,
  'created_at': '2026-10-15T00:00:00Z',
  'store': {'id': 1, 'name': 'Al Faris Parts'},
  'part_name': 'Front headlight',
  'currency': 'SAR',
  'price_scale': 100,
  'quantity': 2,
  'requested_unit_price': 12345,
  'unit_price': 12345,
  'total_amount': 24690,
  'can_accept': true,
  'can_reject': true,
  'images': [],
};

class FakeManagedOrders implements ProviderManagedOrdersRepository {
  List<ProviderManagedOrder> items = [];
  final calls = <(ProviderOrderQuery, int)>[];
  final responses = <(int, bool)>[];
  Future<ProviderManagedOrdersPage> Function(ProviderOrderQuery, int)? onList;
  Future<ProviderManagedOrder> Function(ProviderOrderKey)? onGet;
  Future<ProviderManagedOrder> Function(ProviderManagedOrder, bool)? onRespond;
  @override
  Future<ProviderManagedOrdersPage> list(
    ProviderOrderQuery query, {
    int page = 1,
  }) async {
    calls.add((query, page));
    if (onList != null) return onList!(query, page);
    final filtered = items
        .where(
          (order) =>
              (query.kind == ProviderOrderKind.paid
                  ? order.isPaid
                  : order.type == 'specific') &&
              (query.status == null || order.status == query.status),
        )
        .toList();
    return ProviderManagedOrdersPage(filtered, 1, 1, filtered.length);
  }

  @override
  Future<ProviderManagedOrder> get(ProviderOrderKey key) async =>
      onGet?.call(key) ?? items.firstWhere((order) => order.id == key.id);
  @override
  Future<ProviderManagedOrder> respond(
    ProviderManagedOrder order, {
    required bool accept,
  }) async {
    responses.add((order.id, accept));
    if (onRespond != null) return onRespond!(order, accept);
    final updated = testManagedOrder(
      id: order.id,
      status: accept ? 'awaiting_payment' : 'rejected',
    );
    items = [...items.where((item) => item.id != order.id), updated];
    return updated;
  }
}
