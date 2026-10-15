import '../../../../core/api/api_failure.dart';
import '../../domain/entities/provider_general_request.dart';
import '../../domain/repositories/provider_general_requests_repository.dart';
import '../data_sources/provider_general_requests_remote_data_source.dart';

class ProviderGeneralRequestsRepositoryImpl
    implements ProviderGeneralRequestsRepository {
  const ProviderGeneralRequestsRepositoryImpl(this.remote);
  final ProviderGeneralRequestsRemoteDataSource remote;
  @override
  Future<ProviderGeneralRequestsPage> list({int? cityId, int page = 1}) async {
    try {
      return (await remote.list(cityId: cityId, page: page)).toEntity();
    } on FormatException {
      throw const ApiFailure.unexpected();
    }
  }

  @override
  Future<ProviderGeneralRequest> get(int id) async {
    try {
      return (await remote.get(id)).toEntity();
    } on FormatException {
      throw const ApiFailure.unexpected();
    }
  }
}
