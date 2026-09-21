import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sahala/core/service/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys used to persist values in [LocalStorageService], kept in one place
/// to avoid typo'd/duplicated key strings across call sites.
class _StorageKeys {
  static const firebaseToken = 'firebaseToken';
  static const trackingIdentifier = 'trackingIdentifier';
  static const source = 'source';
  static const userId = 'userId';
  static const mobile = 'mobile';
  static const email = 'email';
  static const name = 'name';
  static const currentLanguage = 'currentLanguage';
  static const baseUrl = 'baseUrl';
  static const isLoggedIn = 'isLoggedIn';

  /// Secure-storage key (Keychain/Keystore), not `shared_preferences`.
  static const token = 'token';
}

/// App-wide local data storage: plain values (via `shared_preferences`) and
/// one secure value (via `flutter_secure_storage`, Keychain-backed on
/// iOS/macOS, Keystore/EncryptedSharedPreferences-backed on Android) behind
/// one set of easy getters/setters.
///
/// Ported from the iOS codebase's `Authenticator` (a `UserDefaults` +
/// `KeychainSwift` facade), renamed since "Authenticator" describes what
/// most of its fields are used *for* (an auth session), not what the class
/// itself does (local storage) - and this project already has an actual
/// auth layer (`features/authentication/`) that name would be confused
/// with.
///
/// Differences from the Swift source, and why:
///  * All the plain (non-secure) getters/setters stay synchronous, same as
///    Swift - `shared_preferences` loads every value into memory on
///    [initialize], so reads/writes after that are synchronous cache hits;
///    persistence to disk happens in the background (errors are logged via
///    [AppLogger.error], not thrown - a setter can't usefully throw
///    synchronously for a write that fails asynchronously).
///  * [token] can't be a *real* synchronous getter the way the others are:
///    `flutter_secure_storage` has no synchronous API at all (Keychain/
///    Keystore access always crosses a platform channel). [initialize]
///    reads it once into memory so the getter can still look synchronous
///    afterwards, but [setToken] has to stay `Future<void>` - it updates
///    the in-memory cache immediately (so a read right after doesn't have
///    to wait) and persists to secure storage in the background.
///  * `source`'s Swift type was `Any?`, but its getter/setter only ever
///    round-tripped it as a `String` (`UserDefaults...string(forKey:)`) -
///    typed as `String?` here to match what it actually does.
///  * `currentLanguage` was stored wrapped in a single-element array
///    (`UserDefaults...set([newValue], forKey:)` /
///    `...array(forKey:)?.first`) - no reason for that turned up in what
///    was given, and there's no other consumer of this Flutter app's
///    storage to stay wire-compatible with, so it's a plain string here.
///    Note this app also already persists its locale via
///    `easy_localization` itself; [currentLanguage] here is a separate
///    value - reconcile the two if you want a single source of truth.
///  * `trakingIdintifer` -> [trackingIdentifier] (typo fix; it's just an
///    identifier name, not a stored value or wire format).
///  * `baseUrl` here is a runtime-overridable stored value, independent of
///    `AppConfig.baseUrl` (`lib/core/config/app_config.dart`), which is a
///    compile-time constant picked by `Environment`. Kept both as-is since
///    reconciling them wasn't asked for - this one is for something like a
///    QA/debug screen that overrides the API base URL at runtime.
class LocalStorageService {
  LocalStorageService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;
  late final SharedPreferences _prefs;
  String? _cachedToken;

  /// Loads persisted values into memory. Call once during app startup,
  /// before anything reads/writes through this service.
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _cachedToken = await _secureStorage.read(key: _StorageKeys.token);
  }

  String? get firebaseToken => _prefs.getString(_StorageKeys.firebaseToken);
  set firebaseToken(String? value) =>
      _setString(_StorageKeys.firebaseToken, value);

  String? get trackingIdentifier =>
      _prefs.getString(_StorageKeys.trackingIdentifier);
  set trackingIdentifier(String? value) =>
      _setString(_StorageKeys.trackingIdentifier, value);

  String? get source => _prefs.getString(_StorageKeys.source);
  set source(String? value) => _setString(_StorageKeys.source, value);

  String? get userId => _prefs.getString(_StorageKeys.userId);
  set userId(String? value) => _setString(_StorageKeys.userId, value);

  String? get mobile => _prefs.getString(_StorageKeys.mobile);
  set mobile(String? value) => _setString(_StorageKeys.mobile, value);

  String? get email => _prefs.getString(_StorageKeys.email);
  set email(String? value) => _setString(_StorageKeys.email, value);

  String? get name => _prefs.getString(_StorageKeys.name);
  set name(String? value) => _setString(_StorageKeys.name, value);

  String? get currentLanguage =>
      _prefs.getString(_StorageKeys.currentLanguage);
  set currentLanguage(String? value) =>
      _setString(_StorageKeys.currentLanguage, value);

  String? get baseUrl => _prefs.getString(_StorageKeys.baseUrl);
  set baseUrl(String? value) => _setString(_StorageKeys.baseUrl, value);

  bool get isLoggedIn => _prefs.getBool(_StorageKeys.isLoggedIn) ?? false;
  set isLoggedIn(bool value) {
    unawaited(
      _runPersist(
        _StorageKeys.isLoggedIn,
        () => _prefs.setBool(_StorageKeys.isLoggedIn, value),
      ),
    );
  }

  /// The secure auth token. Reads the in-memory cache warmed by
  /// [initialize] - use [setToken] to change it (a plain setter can't be
  /// `async`).
  String? get token => _cachedToken;

  Future<void> setToken(String? value) async {
    _cachedToken = value;
    try {
      if (value == null) {
        await _secureStorage.delete(key: _StorageKeys.token);
      } else {
        await _secureStorage.write(key: _StorageKeys.token, value: value);
      }
    } catch (error, stackTrace) {
      await AppLogger.error(
        error,
        stackTrace: stackTrace,
        reason: 'Failed to persist token',
      );
    }
  }

  void _setString(String key, String? value) {
    unawaited(
      _runPersist(
        key,
        () => value == null ? _prefs.remove(key) : _prefs.setString(key, value),
      ),
    );
  }

  Future<void> _runPersist(String key, Future<void> Function() write) async {
    try {
      await write();
    } catch (error, stackTrace) {
      await AppLogger.error(
        error,
        stackTrace: stackTrace,
        reason: 'Failed to persist $key',
      );
    }
  }
}
