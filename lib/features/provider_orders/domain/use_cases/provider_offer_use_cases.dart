import '../../../../core/media/image_upload_policy.dart';
import '../entities/provider_offer.dart';
import '../repositories/provider_offers_repository.dart';

class GetProviderOffers {
  const GetProviderOffers(this._repository);
  final ProviderOffersRepository _repository;
  Future<ProviderOffersPage> call({int page = 1, int? orderId}) {
    if (page < 1 || (orderId != null && orderId < 1)) {
      throw ArgumentError('Invalid offer query.');
    }
    return _repository.list(page: page, orderId: orderId);
  }
}

class GetProviderOffer {
  const GetProviderOffer(this._repository);
  final ProviderOffersRepository _repository;
  Future<ProviderOffer> call(int id) {
    if (id < 1) throw ArgumentError('Invalid offer.');
    return _repository.get(id);
  }
}

class SaveProviderOffer {
  const SaveProviderOffer(this._repository);
  final ProviderOffersRepository _repository;
  Future<ProviderOffer> call(ProviderOfferCommand command) {
    if (command.orderId < 1 ||
        command.storeId < 1 ||
        command.price < 1 ||
        command.price > 2147483647 ||
        (command.offerId != null && command.offerId! < 1) ||
        command.notes.runes.length > 1000 ||
        (command.photos?.length ?? 0) > ImageUploadPolicy.maxFiles ||
        (command.photos?.any(
              (photo) =>
                  photo.bytes.isEmpty ||
                  photo.bytes.length > ImageUploadPolicy.maxBytes ||
                  !ImageUploadPolicy.mimeTypes.contains(photo.mimeType),
            ) ??
            false)) {
      throw ArgumentError('Invalid offer submission.');
    }
    return _repository.save(command);
  }
}

class WithdrawProviderOffer {
  const WithdrawProviderOffer(this._repository);
  final ProviderOffersRepository _repository;
  Future<void> call(ProviderOffer offer) {
    if (!offer.canWithdraw ||
        offer.status != 'pending' ||
        offer.orderStatus != 'pending') {
      throw StateError('Offer cannot be withdrawn.');
    }
    return _repository.withdraw(offer);
  }
}
