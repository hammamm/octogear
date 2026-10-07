import '../../../storefront/domain/entities/storefront_car_catalog.dart';
import '../../domain/entities/part_request.dart';
import '../../domain/repositories/part_request_repository.dart';
import '../data_sources/part_request_remote_data_source.dart';
import '../models/part_request_dto.dart';

class PartRequestRepositoryImpl implements PartRequestRepository {
  const PartRequestRepositoryImpl(this._remote);
  final PartRequestRemoteDataSource _remote;
  @override
  Future<StorefrontCarComponent> getComponent(PartRequestKey key) async =>
      (await _remote.getComponent(key)).toEntity();
  @override
  Future<PartRequestReceipt> submit(PartRequestCommand command) async =>
      (await _remote.submit(PartRequestDto(command))).toEntity();
}
