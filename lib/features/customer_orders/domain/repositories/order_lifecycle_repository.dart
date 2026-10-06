enum OrderLifecycleAction { cancel, received }

abstract interface class OrderLifecycleRepository {
  Future<void> submit(int orderId, OrderLifecycleAction action);
}
