import '../entities/order_lifecycle_action.dart';

abstract interface class OrderLifecycleRepository {
  Future<void> submit(int orderId, OrderLifecycleAction action);
}
