import '../../../../core/api/api_failure.dart';
import '../entities/customer_order.dart';
import '../repositories/customer_orders_repository.dart';

/// Recheck offer membership, eligibility and the price the customer saw.
/// The server still validates atomically when the following write arrives.
class VerifyCustomerOfferUseCase {
  const VerifyCustomerOfferUseCase(this._orders);
  final CustomerOrdersRepository _orders;
  Future<void> call(int orderId, CustomerOrderOffer displayed) async {
    final order = await _orders.get(orderId);
    final current = order.offers
        .where((item) => item.id == displayed.id)
        .firstOrNull;
    if (current == null ||
        !canRespondToOffer(order, current) ||
        current.totalPrice != displayed.totalPrice) {
      throw const ApiFailure(type: ApiFailureType.badRequest, statusCode: 409);
    }
  }
}
