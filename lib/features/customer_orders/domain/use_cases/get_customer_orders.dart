import '../entities/customer_order.dart';
import '../repositories/customer_orders_repository.dart';

class GetCustomerOrders {
  const GetCustomerOrders(this.repository);
  final CustomerOrdersRepository repository;
  Future<CustomerOrdersPage> call(CustomerOrderFilter filter, {int page = 1}) =>
      repository.list(filter: filter, page: page);
}

class GetCustomerOrder {
  const GetCustomerOrder(this.repository);
  final CustomerOrdersRepository repository;
  Future<CustomerOrder> call(int id) => repository.get(id);
}
