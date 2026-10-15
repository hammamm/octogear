import '../entities/provider_general_request.dart';

abstract interface class ProviderGeneralRequestsRepository {
  Future<ProviderGeneralRequestsPage> list({int? cityId, int page = 1});
  Future<ProviderGeneralRequest> get(int id);
}
