import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../localization/app_locale.dart';

/// The narrow secure-session contract used by the application and tests.
abstract interface class SessionStorage {
  String? get cachedAccessToken;
 
  Future<String?> readAccessToken();
  Future<void> saveAccessToken(String accessToken);
  Future<void> clearSession();
}

/// The app-specific cache boundary for non-sensitive user data.
///
/// An access token never belongs here. A cached profile improves the next
/// render only; a fresh server profile remains the session source of truth.
abstract interface class ProfileCacheStorage {
  String? get cachedProfileJson;

  Future<String?> readCachedProfileJson();
  Future<void> saveCachedProfileJson(String profileJson);
  Future<void> clearCachedProfile();
}

/// Stores OctoGear's sensitive session in Keychain/Keystore and its selected
/// locale in preferences. No feature may access either platform package
/// directly.
class AppStorage implements SessionStorage, ProfileCacheStorage {
  AppStorage({
    FlutterSecureStorage? secureStorage,
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  static const _accessTokenKey = 'octogear.session.access_token';
  static const _cachedProfileKey = 'octogear.session.profile';
  static const _localeKey = 'octogear.preferences.locale';

  final FlutterSecureStorage _secureStorage;
  final Future<SharedPreferences> Function() _preferencesLoader;

  Future<void>? _initialization;
  SharedPreferences? _preferences;
  String? _cachedAccessToken;
  String? _cachedProfileJson;
  AppLocale _cachedLocale = AppLocale.arabic;

  @override
  String? get cachedAccessToken => _cachedAccessToken;

  @override
  String? get cachedProfileJson => _cachedProfileJson;

  AppLocale get cachedLocale => _cachedLocale;

  Future<void> initialize() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    final preferences = await _preferencesLoader();
    final accessToken = await _secureStorage.read(key: _accessTokenKey);

    _preferences = preferences;
    _cachedAccessToken = _normaliseToken(accessToken);
    _cachedProfileJson = preferences.getString(_cachedProfileKey);
    _cachedLocale = AppLocale.fromCode(preferences.getString(_localeKey));
  }

  @override
  Future<String?> readAccessToken() async {
    await initialize();
    return _cachedAccessToken;
  }

  @override
  Future<void> saveAccessToken(String accessToken) async {
    final normalizedToken = _normaliseToken(accessToken);
    if (normalizedToken == null) {
      throw ArgumentError.value(accessToken, 'accessToken', 'Cannot be empty.');
    }

    await initialize();
    _cachedAccessToken = normalizedToken;
    await _secureStorage.write(key: _accessTokenKey, value: normalizedToken);
  }

  @override
  Future<void> clearSession() async {
    await initialize();
    // Remove the in-memory value first, so no subsequent request can reuse an
    // invalid token even if the platform write reports an error.
    _cachedAccessToken = null;
    _cachedProfileJson = null;
    await Future.wait<void>([
      _secureStorage.delete(key: _accessTokenKey),
      _preferences!.remove(_cachedProfileKey).then<void>((_) {}),
    ]);
  }

  @override
  Future<String?> readCachedProfileJson() async {
    await initialize();
    return _cachedProfileJson;
  }

  @override
  Future<void> saveCachedProfileJson(String profileJson) async {
    await initialize();
    _cachedProfileJson = profileJson;
    await _preferences!.setString(_cachedProfileKey, profileJson);
  }

  @override
  Future<void> clearCachedProfile() async {
    await initialize();
    _cachedProfileJson = null;
    await _preferences!.remove(_cachedProfileKey);
  }

  Future<void> saveLocale(AppLocale locale) async {
    await initialize();
    _cachedLocale = locale;
    await _preferences!.setString(_localeKey, locale.code);
  }

  String? _normaliseToken(String? value) {
    final token = value?.trim();
    return token == null || token.isEmpty ? null : token;
  }
}
