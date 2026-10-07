import '../repositories/order_management_repository.dart';

class DeleteCustomerOrderUseCase {
  const DeleteCustomerOrderUseCase(this._repository);
  final OrderManagementRepository _repository;

  Future<void> call(int orderId, String token) =>
      _repository.delete(orderId, token);
}
