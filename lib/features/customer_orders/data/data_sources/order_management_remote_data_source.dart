import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../models/order_changes_dto.dart';

class OrderManagementRemoteDataSource {
  const OrderManagementRemoteDataSource(this.api);
  final ApiClient api;
  Future<void> update(
    int orderId,
    String token,
    OrderChangesDto changes,
  ) async {
    final result = await api.patch<bool>(
      'customer/orders/$orderId',
      requiresAuthentication: true,
      data: {...changes.toJson(), 'edit_token': token},
      decode: (data) =>
          data is Map && data['id'] == orderId && data['edit_token'] is String,
    );
    if (result.data != true) throw const ApiFailure.unexpected();
  }

  Future<void> delete(int orderId, String token) async {
    final result = await api.delete<bool>(
      'customer/orders/$orderId',
      requiresAuthentication: true,
      data: {'edit_token': token},
      decode: (data) =>
          data is Map && data['id'] == orderId && data['deleted'] == true,
    );
    if (result.data != true) throw const ApiFailure.unexpected();
  }
}
