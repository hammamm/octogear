import 'package:octogear/features/customer_orders/domain/entities/order_lifecycle_action.dart';
import '../../../../core/api/api_failure.dart';
import '../entities/customer_order.dart';
import '../repositories/customer_orders_repository.dart';

class VerifyOrderLifecycleUseCase {
  const VerifyOrderLifecycleUseCase(this._orders);
  final CustomerOrdersRepository _orders;
  Future<void> call(
    CustomerOrder displayed,
    OrderLifecycleAction action,
  ) async {
    final latest = await _orders.get(displayed.id);
    if (latest.status != displayed.status ||
        latest.acceptedOfferId != displayed.acceptedOfferId ||
        !(action == OrderLifecycleAction.cancel
            ? latest.canCancel
            : latest.canConfirmReceived)) {
      throw const ApiFailure(type: ApiFailureType.badRequest, statusCode: 409);
    }
  }
}
