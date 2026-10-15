import 'package:octogear/core/storage/provider_order_filter_storage.dart';
import 'package:octogear/features/provider_orders/domain/entities/provider_general_request.dart';
import 'package:octogear/features/provider_orders/domain/repositories/provider_general_requests_repository.dart';

ProviderGeneralRequest generalRequest({int id = 1, int cityId = 1}) =>
    ProviderGeneralRequest(
      id: id,
      createdAt: DateTime.utc(2026, 10, 15),
      status: 'pending',
      partName: 'Front headlight',
      cityId: cityId,
      cityName: cityId == 1 ? 'Riyadh' : 'Jeddah',
      carName: 'Camry',
      companyName: 'Toyota',
      year: 2020,
      notes: 'Right side headlight',
    );
ProviderGeneralRequestsPage requestPage(
  List<ProviderGeneralRequest> items, {
  int page = 1,
  int lastPage = 1,
  int? total,
}) => ProviderGeneralRequestsPage(
  items: items,
  page: page,
  lastPage: lastPage,
  total: total ?? items.length,
);

class FakeGeneralRequests implements ProviderGeneralRequestsRepository {
  final calls = <(int?, int)>[];
  final detailCalls = <int>[];
  Future<ProviderGeneralRequestsPage> Function(int?, int)? onList;
  Future<ProviderGeneralRequest> Function(int)? onGet;
  @override
  Future<ProviderGeneralRequestsPage> list({int? cityId, int page = 1}) {
    calls.add((cityId, page));
    return onList?.call(cityId, page) ??
        Future.value(requestPage([generalRequest(cityId: cityId ?? 1)]));
  }

  @override
  Future<ProviderGeneralRequest> get(int id) {
    detailCalls.add(id);
    return onGet?.call(id) ?? Future.value(generalRequest(id: id));
  }
}

class MemoryOrderFilterStorage implements ProviderOrderFilterStorage {
  final values = <int, int>{};
  @override
  int? readProviderOrderCity(int userId) => values[userId];
  @override
  Future<void> saveProviderOrderCity(int userId, int? cityId) async {
    if (cityId == null) {
      values.remove(userId);
    } else {
      values[userId] = cityId;
    }
  }
}

Map<String, dynamic> generalRequestJson({int id = 1, int cityId = 1}) => {
  'id': id,
  'order_type': 'general',
  'status': 'pending',
  'component_name': 'Front headlight',
  'city': {'id': cityId, 'name': 'Riyadh'},
  'created_at': '2026-10-15T10:00:00Z',
  'description': 'Right side headlight',
  'vehicle_details': {
    'car_name': 'Camry',
    'company_name': 'Toyota',
    'manufacturing_year': 2020,
  },
  'images': <Object?>[],
};
