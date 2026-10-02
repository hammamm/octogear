import '../entities/customer_order.dart';

abstract interface class CustomerOrdersRepository {
  Future<CustomerOrdersPage> list({
    required CustomerOrderFilter filter,
    required int page,
  });
  Future<CustomerOrder> get(int id);
}
