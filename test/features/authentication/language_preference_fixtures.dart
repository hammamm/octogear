import 'package:octogear/core/storage/app_storage.dart';
import 'package:octogear/features/authentication/domain/repositories/language_preference_repository.dart';

/// In-memory account-language dependencies for full-app widget fixtures.
class FakeLanguageSessionStorage implements SessionStorage {
  String? _token = 'widget-test-session';
  @override
  String? get cachedAccessToken => _token;
  @override
  Future<String?> readAccessToken() async => _token;
  @override
  Future<void> saveAccessToken(String accessToken) async {
    _token = accessToken;
  }

  @override
  Future<void> clearSession() async {
    _token = null;
  }
}

class FakeLanguagePreferenceRepository implements LanguagePreferenceRepository {
  final saved = <String>[];
  @override
  Future<void> save({
    required String language,
    required String sessionToken,
  }) async {
    saved.add(language);
  }
}
