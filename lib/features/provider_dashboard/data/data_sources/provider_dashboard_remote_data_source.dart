import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../domain/entities/provider_dashboard.dart';
import '../models/provider_dashboard_dto.dart';

class ProviderDashboardRemoteDataSource {
  const ProviderDashboardRemoteDataSource(this.api);
  final ApiClient api;

  Future<ProviderDashboardDto> getDashboard(
    ProviderDashboardQuery query,
  ) async {
    _validateStore(query.storeId);
    final response = await api.get<ProviderDashboardDto>(
      'provider/dashboard',
      requiresAuthentication: true,
      queryParameters: {
        'period': query.period.apiValue,
        'store_id': ?query.storeId,
      },
      decode: ProviderDashboardDto.fromJson,
    );
    final result = response.data;
    if (result == null ||
        result.value.selectedStoreId != query.storeId ||
        result.value.period != query.period) {
      throw const ApiFailure.unexpected();
    }
    return result;
  }

  Future<ProviderDashboardActivityPageDto> getActivity(
    ProviderDashboardActivityQuery query, {
    int page = 1,
  }) async {
    _validateStore(query.storeId);
    if (page < 1) throw ArgumentError.value(page);
    final response = await api.get<List<ProviderDashboardOrderDto>>(
      'provider/dashboard/orders',
      requiresAuthentication: true,
      queryParameters: {
        'section': query.section.apiValue,
        'store_id': ?query.storeId,
        'page': page,
      },
      decode: (data) {
        if (data is! List) {
          throw const FormatException('Invalid dashboard activity list.');
        }
        return data
            .map(ProviderDashboardOrderDto.fromJson)
            .toList(growable: false);
      },
    );
    final items = response.data;
    final meta = response.pagination;
    if (items == null ||
        meta == null ||
        meta.currentPage != page ||
        meta.total < items.length ||
        items.map((item) => item.value.id).toSet().length != items.length ||
        items.any(
          (item) =>
              (query.storeId != null && item.value.store.id != query.storeId) ||
              !matchesDashboardSection(item.value, query.section),
        )) {
      throw const ApiFailure.unexpected();
    }
    return ProviderDashboardActivityPageDto(
      items,
      page,
      meta.lastPage,
      meta.total,
    );
  }
}

void _validateStore(int? storeId) {
  if (storeId != null && storeId < 1) throw ArgumentError.value(storeId);
}
