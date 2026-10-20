import '../entities/provider_offer.dart';

abstract interface class ProviderOffersRepository {
  Future<ProviderOffersPage> list({
    int page = 1,
    int? orderId,
    int? conversationId,
  });
  Future<ProviderOffer> get(int id);
  Future<ProviderOffer> save(ProviderOfferCommand command);
  Future<void> withdraw(ProviderOffer offer);
}
