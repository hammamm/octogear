import '../../../storefront/domain/entities/storefront_car_catalog.dart';
import '../entities/part_request.dart';

abstract interface class PartRequestRepository {
  Future<StorefrontCarComponent> getComponent(PartRequestKey key);
  Future<PartRequestReceipt> submit(PartRequestCommand command);
}
