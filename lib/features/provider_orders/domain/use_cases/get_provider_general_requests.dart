import '../entities/provider_general_request.dart';
import '../repositories/provider_general_requests_repository.dart';

class GetProviderGeneralRequests {
  const GetProviderGeneralRequests(this.repository);
  final ProviderGeneralRequestsRepository repository;
  Future<ProviderGeneralRequestsPage> call({int? cityId, int page = 1}) {
    if (page < 1 || (cityId != null && cityId < 1)) {
      throw ArgumentError('Invalid request filter.');
    }
    return repository.list(cityId: cityId, page: page);
  }
}

class GetProviderGeneralRequest {
  const GetProviderGeneralRequest(this.repository);
  final ProviderGeneralRequestsRepository repository;
  Future<ProviderGeneralRequest> call(int id) {
    if (id < 1) throw ArgumentError.value(id, 'id');
    return repository.get(id);
  }
}
