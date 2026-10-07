import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';

class OfferActionsRemoteDataSource {
  const OfferActionsRemoteDataSource(this.api);
  final ApiClient api;

  Future<void> accept({required int orderId, required int offerId}) async {
    final result = await api.post<bool>(
      'customer/orders/$orderId/accept-offer',
      requiresAuthentication: true,
      data: {'offer_id': offerId},
      decode: (data) =>
          data is Map &&
          data['id'] == orderId &&
          data['accepted_offer_id'] == offerId &&
          data['status'] == 'awaiting_payment',
    );
    if (result.data != true) throw const ApiFailure.unexpected();
  }

  Future<void> reject({
    required int orderId,
    required int offerId,
    String? reason,
  }) async {
    final trimmed = reason?.trim();
    final result = await api.post<bool>(
      'customer/orders/$orderId/offers/$offerId/reject',
      requiresAuthentication: true,
      data: {
        if (trimmed != null && trimmed.isNotEmpty) 'rejection_reason': trimmed,
      },
      decode: (data) =>
          data is Map && data['id'] == offerId && data['status'] == 'rejected',
    );
    if (result.data != true) throw const ApiFailure.unexpected();
  }
}
