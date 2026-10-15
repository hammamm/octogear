import '../../domain/entities/provider_store.dart';

class ProviderStoreDto {
  static ProviderStore fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Invalid owned store.');
    }
    final id = value['id'];
    final name = _text(value['name']) ?? _text(value['nick_name']);
    final status = _text(value['status']);
    if (id is! int || id <= 0 || name == null || status == null) {
      throw const FormatException('Missing owned store identity or status.');
    }
    final city = value['city'];
    if (city != null && city is! Map<String, dynamic>) {
      throw const FormatException('Invalid store city.');
    }
    final companies = value['companies'] ?? const [];
    if (companies is! List) {
      throw const FormatException('Invalid store brands.');
    }
    return ProviderStore(
      id: id,
      name: name,
      status: switch (status) {
        'active' => ProviderStoreStatus.active,
        'inactive' => ProviderStoreStatus.inactive,
        _ => ProviderStoreStatus.unknown,
      },
      mobile: _text(value['mobile']),
      city: city == null ? null : _text(city['name']),
      location: _text(value['url_location']),
      brands: List.unmodifiable(
        companies.map((company) {
          if (company is! Map<String, dynamic>) {
            throw const FormatException('Invalid store brand.');
          }
          return _text(company['name']) ??
              (throw const FormatException('Missing store brand name.'));
        }),
      ),
    );
  }

  static String? _text(Object? value) {
    if (value == null) return null;
    if (value is! String) throw const FormatException('Invalid store text.');
    final text = value.trim();
    return text.isEmpty ? null : text;
  }
}
