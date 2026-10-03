import '../entities/general_request.dart';

abstract interface class GeneralRequestRepository {
  Future<RequestComponentsPage> components({
    required String search,
    required int page,
  });
  Future<int> submit(GeneralRequestCommand command);
}
