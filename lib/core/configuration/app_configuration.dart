import 'package:flutter/foundation.dart';

/// The selected deployment target for OctoGear.
enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment fromDartDefines() => parse(
    const String.fromEnvironment('OCTOGEAR_ENV', defaultValue: 'development'),
  );

  static AppEnvironment parse(String value) {
    return switch (value.trim().toLowerCase()) {
      'development' || 'dev' => AppEnvironment.development,
      'staging' || 'test' => AppEnvironment.staging,
      'production' || 'prod' => AppEnvironment.production,
      _ => throw ArgumentError.value(
        value,
        'OCTOGEAR_ENV',
        'Use development, staging, or production.',
      ),
    };
  }
}

/// Immutable configuration resolved before the API/session providers start.
class AppConfiguration {
  const AppConfiguration({required this.environment, required this.apiBaseUrl});

  /// Edit these two URLs here, then rebuild using the desired OCTOGEAR_ENV.
  /// Include /api. Development can use a device-reachable local HTTP address.
  /// Empty values deliberately stop startup until configured.
  // Android: run adb reverse tcp:8000 tcp:8000 to reach Laravel on this PC.
  static const developmentApiBaseUrl = 'http://127.0.0.1:8000/api';
  static const productionApiBaseUrl = ''; // HTTPS required.

  /// Staging alone gets its URL from this Firebase Client Remote Config key.
  static const apiBaseUrlKey = 'api_base_url';

  final AppEnvironment environment;
  final String apiBaseUrl;

  /// Staging testers can see codes in distributed builds as well as debug.
  /// Production must never retain or display a testing code.
  bool get allowsTestingOtp =>
      environment == AppEnvironment.staging ||
      (kDebugMode && environment == AppEnvironment.development);

  /// Require the full Laravel API base, including /api. No credentials,
  /// query strings, or fragments may become part of a request destination.
  static String? normalizeApiBaseUrl(String? value, {bool allowHttp = false}) {
    if (value == null) return null;
    final normalized = value.trim().replaceFirst(RegExp(r'/+$'), '');
    if (RegExp(r'\s|\\').hasMatch(normalized)) return null;
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        (uri.scheme != 'https' && !(allowHttp && uri.scheme == 'http')) ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.port < 1 ||
        uri.port > 65535 ||
        !uri.path.endsWith('/api')) {
      return null;
    }
    return uri.toString();
  }
}
