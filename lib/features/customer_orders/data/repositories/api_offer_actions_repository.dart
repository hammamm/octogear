import '../../domain/repositories/offer_actions_repository.dart';
import '../data_sources/offer_actions_remote_data_source.dart';

class ApiOfferActionsRepository implements OfferActionsRepository {
  const ApiOfferActionsRepository(this._remote);
  final OfferActionsRemoteDataSource _remote;
  @override
  Future<void> accept({required int orderId, required int offerId}) =>
      _remote.accept(orderId: orderId, offerId: offerId);
  @override
  Future<void> reject({
    required int orderId,
    required int offerId,
    String? reason,
  }) => _remote.reject(orderId: orderId, offerId: offerId, reason: reason);
}
