import '../entities/general_request.dart';
import '../repositories/general_request_repository.dart';

class GetRequestComponentsUseCase {
  const GetRequestComponentsUseCase(this._repository);
  final GeneralRequestRepository _repository;

  Future<RequestComponentsPage> call({
    required String search,
    required int page,
  }) => _repository.components(search: search, page: page);
}
