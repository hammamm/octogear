import 'package:octogear/features/customer_orders/domain/entities/order_lifecycle_action.dart';
import '../../domain/repositories/order_lifecycle_repository.dart';
import '../data_sources/order_lifecycle_remote_data_source.dart';

class ApiOrderLifecycleRepository implements OrderLifecycleRepository {
  const ApiOrderLifecycleRepository(this._remote);
  final OrderLifecycleRemoteDataSource _remote;
  @override
  Future<void> submit(int orderId, OrderLifecycleAction action) =>
      _remote.submit(orderId, action);
}
