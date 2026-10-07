import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../models/general_request_dto.dart';

class GeneralRequestRemoteDataSource {
  const GeneralRequestRemoteDataSource(this.api);
  final ApiClient api;
  Future<RequestComponentsPageDto> components({
    required String search,
    required int page,
  }) async {
    final response = await api.get<List<RequestComponentDto>>(
      'reference/components',
      queryParameters: {
        'page': page,
        'per_page': 20,
        if (search.isNotEmpty) 'search': search,
      },
      decode: requestComponents,
    );
    final meta = response.pagination;
    if (response.data == null || meta == null || meta.currentPage != page) {
      throw const ApiFailure.unexpected();
    }
    return RequestComponentsPageDto(
      items: response.data!,
      page: page,
      lastPage: meta.lastPage,
    );
  }

  Future<int> submit(GeneralRequestDto dto) async {
    final response = await api.postMultipart<int>(
      'customer/orders',
      data: dto.toFormData(),
      requiresAuthentication: true,
      headers: {'Idempotency-Key': dto.command.idempotencyKey},
      decode: generalRequestReceipt,
    );
    if (response.data == null) throw const ApiFailure.unexpected();
    return response.data!;
  }
}
