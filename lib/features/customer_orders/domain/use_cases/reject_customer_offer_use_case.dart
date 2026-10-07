import '../repositories/offer_actions_repository.dart';

class RejectCustomerOfferUseCase {
  const RejectCustomerOfferUseCase(this._repository);
  final OfferActionsRepository _repository;

  Future<void> call({
    required int orderId,
    required int offerId,
    String? reason,
  }) => _repository.reject(orderId: orderId, offerId: offerId, reason: reason);
}
