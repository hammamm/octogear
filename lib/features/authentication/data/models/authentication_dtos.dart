import 'current_user_dto.dart';
import '../../../../core/storage/session_credentials.dart';
import '../../../../core/api/session_credentials_dto.dart';

class CityPageDto {
  const CityPageDto({
    required this.items,
    required this.page,
    required this.lastPage,
  });

  final List<CityDto> items;
  final int page;
  final int lastPage;
}

class OtpVerificationDto {
  const OtpVerificationDto({
    required this.isNew,
    this.accessToken,
    this.temporaryRegistrationToken,
    this.credentials,
  });

  final bool isNew;
  final String? accessToken;
  final String? temporaryRegistrationToken;
  final SessionCredentials? credentials;

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
      credentials: isNew ? null : sessionCredentialsFromJson(json),
    );
  }
}

class AccessTokenDto {
  const AccessTokenDto(this.credentials);

  final SessionCredentials credentials;
  String get value => credentials.accessToken;

  factory AccessTokenDto.fromJson(Object? value) {
    return AccessTokenDto(sessionCredentialsFromJson(value));
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
