import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../domain/entities/provider_managed_order.dart';
import '../models/provider_managed_order_dto.dart';

class ProviderManagedOrdersRemoteDataSource {
  const ProviderManagedOrdersRemoteDataSource(this.api);
  final ApiClient api;
  Future<ProviderManagedOrdersPageDto> list(
    ProviderOrderQuery query, {
    int page = 1,
  }) async {
    final paid = query.kind == ProviderOrderKind.paid;
    final response = await api.get<List<ProviderManagedOrderDto>>(
      'provider/orders/${paid ? 'paid' : 'specific'}',
      requiresAuthentication: true,
      queryParameters: {'page': page, 'status': ?query.status},
      decode: (data) {
        if (data is! List) throw const FormatException('Invalid order list.');
        return data
            .map(ProviderManagedOrderDto.fromJson)
            .toList(growable: false);
      },
    );
    final meta = response.pagination;
    final items = response.data;
    if (items == null ||
        meta == null ||
        meta.currentPage != page ||
        items.any(
          (item) =>
              (paid ? !item.value.isPaid : item.value.type != 'specific') ||
              (query.status != null && item.value.status != query.status),
        )) {
      throw const ApiFailure.unexpected();
    }
    return ProviderManagedOrdersPageDto(items, page, meta.lastPage, meta.total);
  }

  Future<ProviderManagedOrderDto> get(ProviderOrderKey key) async {
    final response = await api.get<ProviderManagedOrderDto>(
      'provider/orders/${key.kind == ProviderOrderKind.paid ? 'paid/' : ''}${key.id}',
      requiresAuthentication: true,
      decode: ProviderManagedOrderDto.fromJson,
    );
    final order = response.data?.value;
    if (order == null ||
        order.id != key.id ||
        (key.kind == ProviderOrderKind.paid
            ? !order.isPaid
            : order.type != 'specific')) {
      throw const ApiFailure.unexpected();
    }
    return response.data!;
  }

  Future<ProviderManagedOrderDto> respond(
    ProviderManagedOrder order, {
    required bool accept,
  }) async {
    final response = await api.post<ProviderManagedOrderDto>(
      'provider/orders/${order.id}/${accept ? 'accept' : 'reject'}',
      requiresAuthentication: true,
      data: accept
          ? {
              'expected_unit_price': order.requestedUnitPrice,
              'expected_quantity': order.quantity,
            }
          : null,
      decode: ProviderManagedOrderDto.fromJson,
    );
    final receipt = response.data?.value;
    if (receipt == null ||
        receipt.id != order.id ||
        receipt.type != 'specific' ||
        (accept
            ? (![
                    'awaiting_payment',
                    'paid',
                    'completed',
                  ].contains(receipt.status) ||
                  receipt.unitPrice != order.requestedUnitPrice ||
                  receipt.quantity != order.quantity)
            : receipt.status != 'rejected')) {
      throw const ApiFailure.unexpected();
    }
    return response.data!;
  }
}
