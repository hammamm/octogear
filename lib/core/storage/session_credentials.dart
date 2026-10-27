/// Credentials are infrastructure values, never navigation or presentation data.
class SessionCredentials {
  const SessionCredentials({
    required this.accessToken,
    required this.refreshToken,
    required this.sessionId,
    required this.accessExpiresAt,
    required this.sessionExpiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final String sessionId;
  final DateTime accessExpiresAt;
  final DateTime sessionExpiresAt;
}

/// One atomic secure-storage record, bound to its API destination.
class StoredSession {
  const StoredSession(this.credentials, this.apiBaseUrl, {this.requestId});
  final SessionCredentials credentials;
  final String apiBaseUrl;
  final String? requestId;
}

abstract interface class RefreshSessionStorage {
  StoredSession? get storedSession;
  Future<bool> saveSession(
    StoredSession session, {
    String? expectedRefreshToken,
  });
}
