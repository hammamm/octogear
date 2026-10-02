import 'package:octogear/features/customer_orders/data/models/customer_order_dto.dart';
import 'package:octogear/features/customer_orders/domain/entities/customer_order.dart';
import 'package:octogear/features/customer_orders/domain/repositories/customer_orders_repository.dart';

Map<String, Object?> orderJson({int id = 1, bool general = false}) => {
  'id': id,
  'order_type': general ? 'general' : 'specific',
  'status': 'pending',
  if (!general) 'quantity': 2,
  'created_at': '2026-09-29T09:30:00.000000Z',
  'currency': 'SAR',
  'price_scale': 100,
  'part_name': general ? null : 'Left wheel',
  'car_name': 'Camry',
  'manufacturing_year': 2020,
  'vehicle_details': general
      ? {
          'car_name': 'Camry',
          'company_name': 'Toyota',
          'manufacturing_year': 2020,
          'transmission_type': 'automatic',
          'color_name': 'White',
          'fuel_type_name': 'Petrol',
        }
      : null,
  'store_car_component': general
      ? null
      : {
          'id': 19,
          'price': 25000,
          'part_number': 'WH-20',
          'store': {'id': 14, 'name': 'Al Faris'},
        },
  'requested_unit_price': general ? null : 15000,
  'offered_price': null,
  'paid_amount': null,
  'notes': 'Check connector',
  'images': [],
  'accepted_offer_id': null,
  'accepted_store': null,
  'offers_count': 0,
  'offers': [],
};
CustomerOrder fixtureOrder({int id = 1, bool general = false}) =>
    CustomerOrderDto.fromJson(orderJson(id: id, general: general)).toEntity();
CustomerOrdersPage ordersPage(
  List<CustomerOrder> orders, {
  int page = 1,
  int last = 1,
  int? total,
}) => CustomerOrdersPage(
  orders: orders,
  currentPage: page,
  lastPage: last,
  total: total ?? orders.length,
);

class FakeOrdersRepository implements CustomerOrdersRepository {
  final calls = <({CustomerOrderFilter filter, int page})>[];
  final detailCalls = <int>[];
  Future<CustomerOrdersPage> Function(CustomerOrderFilter, int)? onList;
  Future<CustomerOrder> Function(int)? onGet;
  @override
  Future<CustomerOrdersPage> list({
    required CustomerOrderFilter filter,
    required int page,
  }) async {
    calls.add((filter: filter, page: page));
    if (onList != null) return onList!(filter, page);
    return ordersPage([
      if (filter != CustomerOrderFilter.general) fixtureOrder(),
      if (filter != CustomerOrderFilter.specific)
        fixtureOrder(id: 2, general: true),
    ]);
  }

  @override
  Future<CustomerOrder> get(int id) async {
    detailCalls.add(id);
    return onGet == null
        ? fixtureOrder(id: id, general: id == 2)
        : await onGet!(id);
  }
}
