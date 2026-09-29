import '../entities/part_request.dart';
import '../repositories/part_request_repository.dart';

class SendPartRequest {
  const SendPartRequest(this._repository);
  final PartRequestRepository _repository;
  Future<PartRequestReceipt> call(PartRequestCommand command) =>
      _repository.submit(command);
}
