import 'package:octogear/features/provider_dashboard/data/models/provider_dashboard_dto.dart';
import 'package:octogear/features/provider_dashboard/domain/entities/provider_dashboard.dart';
import 'package:octogear/features/provider_dashboard/domain/repositories/provider_dashboard_repository.dart';

Map<String, dynamic> dashboardOrderJson({
  int id = 31,
  int storeId = 1,
  String type = 'specific',
  String status = 'paid',
}) => {
  'id': id,
  'order_type': type,
  'status': status,
  'part_name': 'Front headlight',
  'store': {'id': storeId, 'name': 'Al Faris Parts'},
  'customer_name': 'Customer One',
  'quantity': type == 'specific' ? 2 : null,
  'total_amount': 24690,
  'currency': 'SAR',
  'price_scale': 100,
  'accepted_offer_id': type == 'general' && status != 'pending'
      ? id + 100
      : null,
  'created_at': '2026-10-16T09:00:00Z',
  'updated_at': '2026-10-16T10:00:00Z',
  'can_chat': ['awaiting_payment', 'paid'].contains(status),
};

Map<String, dynamic> dashboardJson({int? storeId, String period = 'month'}) => {
  'stores': [
    {'id': 1, 'name': 'Al Faris Parts'},
    {'id': 2, 'name': 'Second Store'},
  ],
  'selected_store_id': storeId,
  'period': period,
  'generated_at': '2026-10-16T12:00:00+03:00',
  'counts': {
    'pending_direct_requests': 1,
    'pending_offers': 3,
    'accepted_offers': 1,
    'paid_orders': 1,
  },
  'sales': {
    'amount': 24690,
    'count': 1,
    'currency': 'SAR',
    'price_scale': 100,
    'from': switch (period) {
      'today' => '2026-10-16T00:00:00+03:00',
      'week' => '2026-10-10T00:00:00+03:00',
      _ => '2026-10-01T00:00:00+03:00',
    },
    'to': '2026-10-16T12:00:00+03:00',
    'timezone': 'Asia/Riyadh',
  },
  'attention': {
    'pending_direct': {
      'total': 1,
      'items': [
        dashboardOrderJson(id: 30, storeId: storeId ?? 1, status: 'pending'),
      ],
    },
    'awaiting_payment': {
      'total': 1,
      'items': [
        dashboardOrderJson(
          id: 32,
          storeId: storeId ?? 1,
          type: 'general',
          status: 'awaiting_payment',
        ),
      ],
    },
    'paid': {
      'total': 1,
      'items': [dashboardOrderJson(storeId: storeId ?? 1)],
    },
  },
  'recent_orders': {
    'total': 3,
    'items': [dashboardOrderJson(storeId: storeId ?? 1)],
  },
};

ProviderDashboard testDashboard({
  int? storeId,
  ProviderDashboardPeriod period = ProviderDashboardPeriod.month,
}) => ProviderDashboardDto.fromJson(
  dashboardJson(storeId: storeId, period: period.apiValue),
).toEntity();

ProviderDashboardOrder testDashboardOrder({
  int id = 31,
  int storeId = 1,
  String type = 'specific',
  String status = 'paid',
}) => ProviderDashboardOrderDto.fromJson(
  dashboardOrderJson(id: id, storeId: storeId, type: type, status: status),
).toEntity();

class FakeDashboard implements ProviderDashboardRepository {
  final queries = <ProviderDashboardQuery>[];
  final activityQueries =
      <({ProviderDashboardActivityQuery query, int page})>[];
  Future<ProviderDashboard> Function(ProviderDashboardQuery query) response =
      (query) async =>
          testDashboard(storeId: query.storeId, period: query.period);
  Future<ProviderDashboardActivityPage> Function(
    ProviderDashboardActivityQuery query,
    int page,
  )
  activityResponse = (query, page) async => ProviderDashboardActivityPage(
    items: [testDashboardOrder()],
    page: page,
    lastPage: page,
    total: 1,
  );

  @override
  Future<ProviderDashboard> getDashboard(ProviderDashboardQuery query) {
    queries.add(query);
    return response(query);
  }

  @override
  Future<ProviderDashboardActivityPage> getActivity(
    ProviderDashboardActivityQuery query, {
    int page = 1,
  }) {
    activityQueries.add((query: query, page: page));
    return activityResponse(query, page);
  }
}
