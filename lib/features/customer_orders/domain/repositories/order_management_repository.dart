import '../entities/order_changes.dart';

abstract interface class OrderManagementRepository {
  Future<void> update(int orderId, String token, OrderChanges changes);
  Future<void> delete(int orderId, String token);
}
