import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../domain/entities/general_request.dart';
import '../models/general_request_dto.dart';

class GeneralRequestRemoteDataSource {
  const GeneralRequestRemoteDataSource(this.api);
  final ApiClient api;
  Future<RequestComponentsPage> components({
    required String search,
    required int page,
  }) async {
    final response = await api.get<List<RequestComponent>>(
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
    return RequestComponentsPage(
      items: response.data!,
      page: page,
      lastPage: meta.lastPage,
    );
  }

  Future<int> submit(GeneralRequestCommand command) async {
    final response = await api.postMultipart<int>(
      'customer/orders',
      data: GeneralRequestDto(command).toFormData(),
      requiresAuthentication: true,
      headers: {'Idempotency-Key': command.idempotencyKey},
      decode: generalRequestReceipt,
    );
    if (response.data == null) throw const ApiFailure.unexpected();
    return response.data!;
  }
}
