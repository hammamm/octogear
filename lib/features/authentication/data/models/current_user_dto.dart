import 'dart:convert';

import '../../domain/entities/app_user.dart';

class CurrentUserDto {
  const CurrentUserDto({
    required this.id,
    required this.fullName,
    required this.mobile,
    required this.type,
    this.city,
  });

  final int id;
  final String fullName;
  final String mobile;
  final String type;
  final CityDto? city;

  factory CurrentUserDto.fromJson(Object? value) {
    final json = _objectMap(value);
    final id = json['id'];
    final fullName = json['full_name'];
    final mobile = json['mobile'];
    final type = json['type'];

    if (id is! num ||
        fullName is! String ||
        mobile is! String ||
        type is! String) {
      throw const FormatException('Current-user response has invalid fields.');
    }

    final cityValue = json['city'];
    return CurrentUserDto(
      id: id.toInt(),
      fullName: fullName,
      mobile: mobile,
      type: type,
      city: cityValue == null ? null : CityDto.fromJson(cityValue),
    );
  }

  AppUser toEntity() {
    final role = AppUserRole.fromApiValue(type);
    if (role == null) {
      throw const FormatException('Current-user response has an unknown role.');
    }

    return AppUser(
      id: id,
      fullName: fullName,
      mobile: mobile,
      role: role,
      city: city == null ? null : AppCity(id: city!.id, name: city!.name),
    );
  }

  String toCacheJson() {
    return jsonEncode({
      'id': id,
      'full_name': fullName,
      'type': type,
      'city': city == null ? null : {'id': city!.id, 'name': city!.name},
    });
  }
}

class CityDto {
  const CityDto({required this.id, required this.name});

  final int id;
  final String name;

  factory CityDto.fromJson(Object? value) {
    final json = _objectMap(value);
    final id = json['id'];
    final name = json['name'];
    if (id is! num || name is! String) {
      throw const FormatException('Current-user city has invalid fields.');
    }
    return CityDto(id: id.toInt(), name: name);
  }
}

Map<String, Object?> _objectMap(Object? value) {
  if (value is! Map) {
    throw const FormatException('Expected a JSON object.');
  }

  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw const FormatException('Expected string JSON keys.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}
