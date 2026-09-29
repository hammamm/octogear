import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../../storefront/data/models/storefront_car_catalog_dto.dart';
import '../../domain/entities/part_request.dart';
import '../models/part_request_dto.dart';

class PartRequestRemoteDataSource {
  const PartRequestRemoteDataSource(this._api);
  final ApiClient _api;

  Future<StorefrontCarComponentDto> getComponent(PartRequestKey key) async {
    final response = await _api.get<StorefrontCarComponentDto>(
      'stores/${key.storeId}/cars/${key.carId}/components/${key.componentId}',
      requiresAuthentication: true,
      decode: StorefrontCarComponentDto.fromJson,
    );
    final component = response.data;
    if (component == null || component.toEntity().id != key.componentId) {
      throw const ApiFailure.unexpected();
    }
    return component;
  }

  Future<PartRequestReceipt> submit(PartRequestDto dto) async {
    final response = await _api.postMultipart<PartRequestReceipt>(
      'customer/orders',
      data: dto.toFormData(),
      requiresAuthentication: true,
      headers: {'Idempotency-Key': dto.command.idempotencyKey},
      decode: partRequestReceiptFromJson,
    );
    final receipt = response.data;
    if (receipt == null || receipt.quantity != dto.command.quantity) {
      throw const ApiFailure.unexpected();
    }
    return receipt;
  }
}
