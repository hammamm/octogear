import '../storage/session_credentials.dart';

/// Shared wire contract for login, refresh and secure record restoration.
SessionCredentials sessionCredentialsFromJson(Object? value) {
  if (value is! Map) throw const FormatException('Missing credentials.');
  String string(String key) {
    final result = value[key];
    if (result is! String || result.trim().isEmpty) {
      throw const FormatException('Invalid credentials.');
    }
    return result;
  }
  final id = string('session_id');
  if (!RegExp(r'^[\da-f]{8}(?:-[\da-f]{4}){3}-[\da-f]{12}$', caseSensitive: false).hasMatch(id)) {
    throw const FormatException('Invalid session ID.');
  }
  final accessExpiry = DateTime.parse(string('access_expires_at')).toUtc();
  final sessionExpiry = DateTime.parse(string('session_expires_at')).toUtc();
  if (accessExpiry.isAfter(sessionExpiry)) {
    throw const FormatException('Invalid credential deadlines.');
  }
  return SessionCredentials(
    accessToken: string('token'), refreshToken: string('refresh_token'),
    sessionId: id, accessExpiresAt: accessExpiry,
    sessionExpiresAt: sessionExpiry,
  );
}

Map<String, Object?> sessionCredentialsToJson(SessionCredentials value) => {
  'token': value.accessToken, 'refresh_token': value.refreshToken,
  'session_id': value.sessionId,
  'access_expires_at': value.accessExpiresAt.toIso8601String(),
  'session_expires_at': value.sessionExpiresAt.toIso8601String(),
};
