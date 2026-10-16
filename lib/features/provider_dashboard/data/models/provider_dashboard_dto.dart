import '../../domain/entities/provider_dashboard.dart';

class ProviderDashboardDto {
  const ProviderDashboardDto._(this.value);
  final ProviderDashboard value;
  ProviderDashboard toEntity() => value;

  factory ProviderDashboardDto.fromJson(Object? value) {
    final json = _map(value);
    final stores = _list(json['stores']).map(_store).toList(growable: false);
    if (stores.map((store) => store.id).toSet().length != stores.length) {
      throw const FormatException('Duplicate dashboard store.');
    }
    final selected = _optionalInteger(
      json['selected_store_id'],
      positive: true,
    );
    if (selected != null && !stores.any((store) => store.id == selected)) {
      throw const FormatException('Invalid dashboard store selection.');
    }
    final period = ProviderDashboardPeriod.values
        .where((period) => period.apiValue == json['period'])
        .firstOrNull;
    if (period == null) {
      throw const FormatException('Invalid dashboard period.');
    }
    final counts = _map(json['counts']);
    final sales = _map(json['sales']);
    final from = _date(sales['from']);
    final to = _date(sales['to']);
    if (from.isAfter(to) ||
        sales['currency'] != 'SAR' ||
        sales['price_scale'] != 100) {
      throw const FormatException('Invalid dashboard sales.');
    }
    final attention = _map(json['attention']);
    ProviderDashboardOrderGroup group(
      Object? value,
      ProviderDashboardSection section,
    ) {
      final json = _map(value);
      final items = _list(json['items'])
          .map((item) => ProviderDashboardOrderDto.fromJson(item).value)
          .toList(growable: false);
      final total = _integer(json['total']);
      if (total < items.length ||
          items.map((item) => item.id).toSet().length != items.length ||
          items.any(
            (item) =>
                !stores.any((store) => store.id == item.store.id) ||
                (selected != null && item.store.id != selected) ||
                !matchesDashboardSection(item, section),
          )) {
        throw const FormatException('Invalid dashboard activity group.');
      }
      return ProviderDashboardOrderGroup(
        items: List.unmodifiable(items),
        total: total,
      );
    }

    return ProviderDashboardDto._(
      ProviderDashboard(
        stores: List.unmodifiable(stores),
        selectedStoreId: selected,
        period: period,
        generatedAt: _date(json['generated_at']),
        counts: ProviderDashboardCounts(
          pendingDirectRequests: _integer(counts['pending_direct_requests']),
          pendingOffers: _integer(counts['pending_offers']),
          acceptedOffers: _integer(counts['accepted_offers']),
          paidOrders: _integer(counts['paid_orders']),
        ),
        sales: ProviderDashboardSales(
          amount: _integer(sales['amount']),
          count: _integer(sales['count']),
          currency: 'SAR',
          priceScale: 100,
          from: from,
          to: to,
          timezone: _text(sales['timezone']),
        ),
        pendingDirect: group(
          attention['pending_direct'],
          ProviderDashboardSection.pendingDirect,
        ),
        awaitingPayment: group(
          attention['awaiting_payment'],
          ProviderDashboardSection.awaitingPayment,
        ),
        paid: group(attention['paid'], ProviderDashboardSection.paid),
        recentOrders: group(
          json['recent_orders'],
          ProviderDashboardSection.recent,
        ),
      ),
    );
  }
}

class ProviderDashboardOrderDto {
  const ProviderDashboardOrderDto._(this.value);
  final ProviderDashboardOrder value;
  ProviderDashboardOrder toEntity() => value;

  factory ProviderDashboardOrderDto.fromJson(Object? value) {
    final json = _map(value);
    final type = _text(json['order_type']);
    final status = _text(json['status']);
    if (!['general', 'specific'].contains(type) ||
        ![
          'pending',
          'awaiting_payment',
          'paid',
          'completed',
          'rejected',
          'cancelled',
        ].contains(status) ||
        json['currency'] != 'SAR' ||
        json['price_scale'] != 100 ||
        json['can_chat'] is! bool) {
      throw const FormatException('Invalid dashboard order.');
    }
    final acceptedOfferId = _optionalInteger(
      json['accepted_offer_id'],
      positive: true,
    );
    if (type == 'general' &&
        ['awaiting_payment', 'paid', 'completed'].contains(status) &&
        acceptedOfferId == null) {
      throw const FormatException('Missing accepted offer identity.');
    }
    return ProviderDashboardOrderDto._(
      ProviderDashboardOrder(
        id: _integer(json['id'], positive: true),
        type: type,
        status: status,
        partName: _optionalText(json['part_name']),
        store: _store(json['store']),
        customerName: _optionalText(json['customer_name']),
        quantity: _optionalInteger(json['quantity'], positive: true),
        totalAmount: _optionalInteger(json['total_amount']),
        acceptedOfferId: acceptedOfferId,
        createdAt: _date(json['created_at']),
        updatedAt: _date(json['updated_at']),
        canChat:
            json['can_chat'] == true &&
            ['awaiting_payment', 'paid'].contains(status),
      ),
    );
  }
}

class ProviderDashboardActivityPageDto {
  const ProviderDashboardActivityPageDto(
    this.items,
    this.page,
    this.lastPage,
    this.total,
  );
  final List<ProviderDashboardOrderDto> items;
  final int page, lastPage, total;
  ProviderDashboardActivityPage toEntity() => ProviderDashboardActivityPage(
    items: List.unmodifiable(items.map((item) => item.toEntity())),
    page: page,
    lastPage: lastPage,
    total: total,
  );
}

bool matchesDashboardSection(
  ProviderDashboardOrder item,
  ProviderDashboardSection section,
) => switch (section) {
  ProviderDashboardSection.pendingDirect =>
    item.type == 'specific' && item.status == 'pending',
  ProviderDashboardSection.awaitingPayment => item.status == 'awaiting_payment',
  ProviderDashboardSection.paid => item.status == 'paid',
  ProviderDashboardSection.recent => true,
};

Map<String, dynamic> _map(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Invalid dashboard object.');
  }
  return value;
}

List<dynamic> _list(Object? value) {
  if (value is! List) {
    throw const FormatException('Invalid dashboard list.');
  }
  return value;
}

int _integer(Object? value, {bool positive = false}) {
  if (value is! int || value < (positive ? 1 : 0)) {
    throw const FormatException('Invalid dashboard integer.');
  }
  return value;
}

int? _optionalInteger(Object? value, {bool positive = false}) =>
    value == null ? null : _integer(value, positive: positive);
String _text(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Invalid dashboard text.');
  }
  return value.trim();
}

String? _optionalText(Object? value) =>
    value == null || value is String && value.trim().isEmpty
    ? null
    : _text(value);
DateTime _date(Object? value) {
  final date = DateTime.tryParse(_text(value));
  if (date == null) {
    throw const FormatException('Invalid dashboard date.');
  }
  return date;
}

ProviderDashboardStore _store(Object? value) {
  final json = _map(value);
  return ProviderDashboardStore(
    id: _integer(json['id'], positive: true),
    name: _text(json['name']),
  );
}
