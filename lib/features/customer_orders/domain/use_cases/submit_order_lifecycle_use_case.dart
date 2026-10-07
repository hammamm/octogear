import 'package:octogear/features/customer_orders/domain/entities/order_lifecycle_action.dart';
import '../repositories/order_lifecycle_repository.dart';

class SubmitOrderLifecycleUseCase {
  const SubmitOrderLifecycleUseCase(this._repository);
  final OrderLifecycleRepository _repository;

  Future<void> call(int orderId, OrderLifecycleAction action) =>
      _repository.submit(orderId, action);
}
