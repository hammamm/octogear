abstract interface class OrderManagementRepository {
  Future<void> update(int orderId, String token, Map<String, Object?> changes);
  Future<void> delete(int orderId, String token);
}
