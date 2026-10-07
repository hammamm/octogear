import '../entities/order_changes.dart';
import '../repositories/order_management_repository.dart';

class UpdateCustomerOrderUseCase {
  const UpdateCustomerOrderUseCase(this._repository);
  final OrderManagementRepository _repository;

  Future<void> call(int orderId, String token, OrderChanges changes) =>
      _repository.update(orderId, token, changes);
}
