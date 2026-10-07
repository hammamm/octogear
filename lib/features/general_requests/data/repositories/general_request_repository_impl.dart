import '../../domain/entities/general_request.dart';
import '../../domain/repositories/general_request_repository.dart';
import '../data_sources/general_request_remote_data_source.dart';
import '../models/general_request_dto.dart';

class GeneralRequestRepositoryImpl implements GeneralRequestRepository {
  const GeneralRequestRepositoryImpl(this.remote);
  final GeneralRequestRemoteDataSource remote;
  @override
  Future<RequestComponentsPage> components({
    required String search,
    required int page,
  }) async => (await remote.components(search: search, page: page)).toEntity();
  @override
  Future<int> submit(GeneralRequestCommand command) =>
      remote.submit(GeneralRequestDto(command));
}
