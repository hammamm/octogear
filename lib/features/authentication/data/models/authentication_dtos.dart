import 'current_user_dto.dart';

class OtpVerificationDto {
  const OtpVerificationDto({
    required this.isNew,
    this.accessToken,
    this.temporaryRegistrationToken,
  });

  final bool isNew;
  final String? accessToken;
  final String? temporaryRegistrationToken;

  factory OtpVerificationDto.fromJson(Object? value) {
    final json = _jsonObject(value);
    final isNew = json['is_new'];
    if (isNew is! bool) {
      throw const FormatException('OTP verification has no is_new value.');
    }

    final accessToken = _nonEmptyString(json['token']);
    final temporaryRegistrationToken = _nonEmptyString(json['temp_token']);
    if (isNew && temporaryRegistrationToken == null) {
      throw const FormatException(
        'New-account verification has no temp token.',
      );
    }
    if (!isNew && accessToken == null) {
      throw const FormatException('Verified account has no access token.');
    }

    return OtpVerificationDto(
      isNew: isNew,
      accessToken: accessToken,
      temporaryRegistrationToken: temporaryRegistrationToken,
    );
  }
}

class AccessTokenDto {
  const AccessTokenDto(this.value);

  final String value;

  factory AccessTokenDto.fromJson(Object? value) {
    final token = _nonEmptyString(_jsonObject(value)['token']);
    if (token == null) {
      throw const FormatException('The response has no access token.');
    }
    return AccessTokenDto(token);
  }
}

List<CityDto> cityListFromJson(Object? value) {
  if (value is! List) {
    throw const FormatException('City data is not a list.');
  }
  return value.map(CityDto.fromJson).toList(growable: false);
}

Map<String, Object?> _jsonObject(Object? value) {
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

String? _nonEmptyString(Object? value) {
  if (value is! String) return null;
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}
