import '../../domain/entities/order_changes.dart';
import '../../domain/repositories/order_management_repository.dart';
import '../data_sources/order_management_remote_data_source.dart';
import '../models/order_changes_dto.dart';

class ApiOrderManagementRepository implements OrderManagementRepository {
  const ApiOrderManagementRepository(this._remote);
  final OrderManagementRemoteDataSource _remote;
  @override
  Future<void> update(int orderId, String token, OrderChanges changes) =>
      _remote.update(orderId, token, OrderChangesDto(changes));
  @override
  Future<void> delete(int orderId, String token) =>
      _remote.delete(orderId, token);
}
