import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../domain/entities/provider_offer.dart';
import '../models/provider_offer_dto.dart';

class ProviderOffersRemoteDataSource {
  const ProviderOffersRemoteDataSource(this.api);
  final ApiClient api;
  Future<ProviderOffersPageDto> list({int page = 1, int? orderId}) async {
    final response = await api.get<List<ProviderOfferDto>>(
      'provider/orders/offers',
      requiresAuthentication: true,
      queryParameters: {'page': page, 'order_id': ?orderId},
      decode: (data) {
        if (data is! List) throw const FormatException('Invalid offer list.');
        return data.map(ProviderOfferDto.fromJson).toList(growable: false);
      },
    );
    final meta = response.pagination;
    if (response.data == null ||
        meta == null ||
        meta.currentPage != page ||
        response.data!.any(
          (offer) => orderId != null && offer.value.orderId != orderId,
        )) {
      throw const ApiFailure.unexpected();
    }
    return ProviderOffersPageDto(
      response.data!,
      page,
      meta.lastPage,
      meta.total,
    );
  }

  Future<ProviderOfferDto> get(int id) async {
    final response = await api.get<ProviderOfferDto>(
      'provider/orders/offers/$id',
      requiresAuthentication: true,
      decode: ProviderOfferDto.fromJson,
    );
    if (response.data?.value.id != id) throw const ApiFailure.unexpected();
    return response.data!;
  }

  Future<ProviderOfferDto> save(ProviderOfferCommand command) async {
    final response = await api.postMultipart<ProviderOfferDto>(
      'provider/orders/${command.orderId}/offer${command.offerId == null ? '' : '/${command.offerId}'}',
      data: providerOfferForm(command),
      requiresAuthentication: true,
      decode: ProviderOfferDto.fromJson,
    );
    final value = response.data?.value;
    if (value == null ||
        value.orderId != command.orderId ||
        value.storeId != command.storeId ||
        value.price != command.price ||
        (command.offerId != null && value.id != command.offerId)) {
      throw const ApiFailure.unexpected();
    }
    return response.data!;
  }

  Future<void> withdraw(ProviderOffer offer) async {
    await api.delete<Object?>(
      'provider/orders/${offer.orderId}/offer/${offer.id}',
      requiresAuthentication: true,
      decode: (data) => data,
    );
  }
}
