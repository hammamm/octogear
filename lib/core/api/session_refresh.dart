import 'package:uuid/uuid.dart';

import '../storage/app_storage.dart';
import '../storage/session_credentials.dart';
import 'api_failure.dart';

typedef RefreshRequest = Future<SessionCredentials> Function(String token, String requestId);

/// One refresh per login at a time; an uncertain response keeps its durable UUID.
class SessionRefresh {
  SessionRefresh({required this.storage, required this.apiBaseUrl, required this.request, required this.onExpired});
  final SessionStorage storage;
  final String apiBaseUrl;
  final RefreshRequest request;
  final void Function() onExpired;
  Future<String?>? _pending;

  RefreshSessionStorage? get _secure => storage is RefreshSessionStorage ? storage as RefreshSessionStorage : null;

  Future<String?> token({String? rejectedToken}) async {
    final record = _secure?.storedSession;
    if (record == null) return storage.cachedAccessToken;
    if (record.apiBaseUrl != apiBaseUrl || !record.credentials.sessionExpiresAt.isAfter(DateTime.now().toUtc())) {
      await invalidate(record.credentials.sessionId);
      throw const ApiFailure(type: ApiFailureType.unauthorized, statusCode: 401);
    }
    if (rejectedToken != null && rejectedToken != record.credentials.accessToken) return record.credentials.accessToken;
    if (rejectedToken == null && record.requestId == null && record.credentials.accessExpiresAt.isAfter(DateTime.now().toUtc().add(const Duration(seconds: 30)))) {
      return record.credentials.accessToken;
    }
    if (_pending case final pending?) return pending;
    final pending = _rotate(record);
    _pending = pending;
    try { return await pending; }
    finally { if (identical(_pending, pending)) _pending = null; }
  }

  Future<String?> _rotate(StoredSession record) async {
    final previous = record.credentials;
    final requestId = record.requestId ?? const Uuid().v4();
    try {
      if (!await _secure!.saveSession(StoredSession(previous, apiBaseUrl, requestId: requestId), expectedRefreshToken: previous.refreshToken)) {
        throw const ApiFailure.unexpected();
      }
      final credentials = await request(previous.refreshToken, requestId);
      if (credentials.sessionId != previous.sessionId || credentials.sessionExpiresAt != previous.sessionExpiresAt) {
        throw const ApiFailure.unexpected();
      }
      if (!await _secure!.saveSession(StoredSession(credentials, apiBaseUrl), expectedRefreshToken: previous.refreshToken)) {
        throw const ApiFailure.unexpected();
      }
      return credentials.accessToken;
    } on ApiFailure catch (failure) {
      if (failure.type == ApiFailureType.unauthorized) await invalidate(previous.sessionId);
      rethrow;
    }
  }

  Future<void> invalidate(String? expectedIdentity) async {
    if (expectedIdentity == null || storage.sessionIdentity != expectedIdentity) return;
    try { await storage.clearSession(); }
    finally { onExpired(); }
  }
}
