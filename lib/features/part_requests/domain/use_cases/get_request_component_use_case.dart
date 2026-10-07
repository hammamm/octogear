import '../../../storefront/domain/entities/storefront_car_catalog.dart';
import '../entities/part_request.dart';
import '../repositories/part_request_repository.dart';

class GetRequestComponentUseCase {
  const GetRequestComponentUseCase(this._repository);
  final PartRequestRepository _repository;

  Future<StorefrontCarComponent> call(PartRequestKey key) =>
      _repository.getComponent(key);
}
