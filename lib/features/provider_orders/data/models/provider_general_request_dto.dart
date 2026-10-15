import '../../domain/entities/provider_general_request.dart';

class ProviderGeneralRequestDto {
  const ProviderGeneralRequestDto._(this.value);
  final ProviderGeneralRequest value;
  ProviderGeneralRequest toEntity() => value;

  factory ProviderGeneralRequestDto.fromJson(Object? value) {
    final json = _map(value);
    final id = _id(json['id']);
    if (json['order_type'] != 'general') {
      throw const FormatException('Expected general request.');
    }
    final date = json['created_at'] is String
        ? DateTime.tryParse(json['created_at'] as String)
        : null;
    final status = _text(json['status']);
    if (date == null || status == null) {
      throw const FormatException('Missing request date or status.');
    }
    final city = json['city'] == null ? null : _map(json['city']);
    final vehicle = json['vehicle_details'] == null
        ? null
        : _map(json['vehicle_details']);
    final offers = json['offers'] ?? const [];
    if (offers is! List) throw const FormatException('Invalid own offers.');
    final images = json['images'] ?? const [];
    if (images is! List) throw const FormatException('Invalid request images.');
    return ProviderGeneralRequestDto._(
      ProviderGeneralRequest(
        id: id,
        ownOffers: List.unmodifiable(
          offers.map((offer) {
            final value = _map(offer);
            return (
              id: _id(value['id']),
              storeId: _id(_map(value['store'])['id']),
              storeName: _text(_map(value['store'])['name']),
            );
          }),
        ),
        createdAt: date,
        status: status,
        partName: _text(json['component_name']),
        cityId: city == null ? null : _id(city['id']),
        cityName: city == null ? null : _text(city['name']),
        carName: _text(vehicle?['car_name']),
        companyName: _text(vehicle?['company_name']),
        year: vehicle?['manufacturing_year'] == null
            ? null
            : _id(vehicle!['manufacturing_year']),
        transmission: _text(vehicle?['transmission_type']),
        color: _text(vehicle?['color_name']),
        fuel: _text(vehicle?['fuel_type_name']),
        notes: _text(json['description'] ?? json['notes']),
        imagePaths: List.unmodifiable(
          images.map((image) {
            final path = _map(image)['url'];
            if (path is! String ||
                !RegExp(
                  '^/api/media/orders/$id/images/[1-9][0-9]*\$',
                ).hasMatch(path)) {
              throw const FormatException(
                'Invalid private request image path.',
              );
            }
            return path;
          }),
        ),
      ),
    );
  }
}

class ProviderGeneralRequestsPageDto {
  const ProviderGeneralRequestsPageDto(
    this.items,
    this.page,
    this.lastPage,
    this.total,
  );
  final List<ProviderGeneralRequestDto> items;
  final int page, lastPage, total;
  ProviderGeneralRequestsPage toEntity() => ProviderGeneralRequestsPage(
    items: List.unmodifiable(items.map((item) => item.toEntity())),
    page: page,
    lastPage: lastPage,
    total: total,
  );
}

Map<String, dynamic> _map(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Expected object.');
  }
  return value;
}

int _id(Object? value) {
  if (value is! int || value <= 0) {
    throw const FormatException('Invalid positive integer.');
  }
  return value;
}

String? _text(Object? value) {
  if (value == null) return null;
  if (value is! String) throw const FormatException('Invalid text.');
  return value.trim().isEmpty ? null : value.trim();
}
