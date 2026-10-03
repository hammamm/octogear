abstract interface class OfferActionsRepository {
  Future<void> accept({required int orderId, required int offerId});
  Future<void> reject({
    required int orderId,
    required int offerId,
    String? reason,
  });
}
