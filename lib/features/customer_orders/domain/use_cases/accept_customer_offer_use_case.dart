import '../repositories/offer_actions_repository.dart';

class AcceptCustomerOfferUseCase {
  const AcceptCustomerOfferUseCase(this._repository);
  final OfferActionsRepository _repository;

  Future<void> call({required int orderId, required int offerId}) =>
      _repository.accept(orderId: orderId, offerId: offerId);
}
