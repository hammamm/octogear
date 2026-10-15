import '../../domain/entities/provider_offer.dart';
import '../../domain/repositories/provider_offers_repository.dart';
import '../data_sources/provider_offers_remote_data_source.dart';

class ProviderOffersRepositoryImpl implements ProviderOffersRepository {
  const ProviderOffersRepositoryImpl(this._remote);
  final ProviderOffersRemoteDataSource _remote;
  @override
  Future<ProviderOffersPage> list({int page = 1, int? orderId}) async =>
      (await _remote.list(page: page, orderId: orderId)).toEntity();
  @override
  Future<ProviderOffer> get(int id) async => (await _remote.get(id)).toEntity();
  @override
  Future<ProviderOffer> save(ProviderOfferCommand command) async =>
      (await _remote.save(command)).toEntity();
  @override
  Future<void> withdraw(ProviderOffer offer) => _remote.withdraw(offer);
}
