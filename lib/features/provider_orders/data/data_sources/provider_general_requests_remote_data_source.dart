import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../models/provider_general_request_dto.dart';

class ProviderGeneralRequestsRemoteDataSource {
  const ProviderGeneralRequestsRemoteDataSource(this.api);
  final ApiClient api;

  Future<ProviderGeneralRequestsPageDto> list({
    int? cityId,
    int page = 1,
  }) async {
    final response = await api.get<List<ProviderGeneralRequestDto>>(
      'provider/orders/general',
      requiresAuthentication: true,
      queryParameters: {'page': page, 'city_id': ?cityId},
      decode: (data) {
        if (data is! List) {
          throw const FormatException('Expected general requests.');
        }
        return data
            .map(ProviderGeneralRequestDto.fromJson)
            .toList(growable: false);
      },
    );
    final items = response.data;
    final meta = response.pagination;
    if (items == null ||
        meta == null ||
        meta.currentPage != page ||
        items.any(
          (item) =>
              item.value.status != 'pending' ||
              (cityId != null && item.value.cityId != cityId),
        )) {
      throw const ApiFailure.unexpected();
    }
    return ProviderGeneralRequestsPageDto(
      items,
      page,
      meta.lastPage,
      meta.total,
    );
  }

  Future<ProviderGeneralRequestDto> get(int id) async {
    final response = await api.get<ProviderGeneralRequestDto>(
      'provider/orders/$id',
      requiresAuthentication: true,
      decode: ProviderGeneralRequestDto.fromJson,
    );
    if (response.data == null || response.data!.value.id != id) {
      throw const ApiFailure.unexpected();
    }
    return response.data!;
  }
}
