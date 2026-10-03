import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../domain/repositories/order_management_repository.dart';

class ApiOrderManagementRepository implements OrderManagementRepository {
  const ApiOrderManagementRepository(this.api);
  final ApiClient api;
  @override
  Future<void> update(
    int orderId,
    String token,
    Map<String, Object?> changes,
  ) async {
    final result = await api.patch<bool>(
      'customer/orders/$orderId',
      requiresAuthentication: true,
      data: {...changes, 'edit_token': token},
      decode: (data) =>
          data is Map && data['id'] == orderId && data['edit_token'] is String,
    );
    if (result.data != true) throw const ApiFailure.unexpected();
  }

  @override
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
