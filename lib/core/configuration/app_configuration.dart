/// The selected deployment target for OctoGear.
enum AppEnvironment {
  development,
  staging,
  production;

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

/// Immutable configuration sourced from `--dart-define` values.
///
/// A deployment changes configuration at build/run time, never by editing
/// source. The default intentionally targets the local Laravel server.
class AppConfiguration {
  const AppConfiguration({required this.environment, required this.apiBaseUrl});

  static const _developmentApiBaseUrl = 'http://127.0.0.1:8000/api';
  static const _stagingApiBaseUrl = 'https://api-staging.octogear.invalid/api';
  static const _productionApiBaseUrl = 'https://api.octogear.invalid/api';

  final AppEnvironment environment;
  final String apiBaseUrl;

  factory AppConfiguration.fromDartDefines() {
    const environmentValue = String.fromEnvironment(
      'OCTOGEAR_ENV',
      defaultValue: 'development',
    );
    const apiBaseUrlOverride = String.fromEnvironment('OCTOGEAR_API_BASE_URL');

    return AppConfiguration.fromValues(
      environmentValue: environmentValue,
      apiBaseUrlOverride: apiBaseUrlOverride,
    );
  }

  factory AppConfiguration.fromValues({
    required String environmentValue,
    String apiBaseUrlOverride = '',
  }) {
    final environment = AppEnvironment.parse(environmentValue);
    final configuredBaseUrl = switch (environment) {
      AppEnvironment.development => _developmentApiBaseUrl,
      AppEnvironment.staging => _stagingApiBaseUrl,
      AppEnvironment.production => _productionApiBaseUrl,
    };
    final apiBaseUrl = apiBaseUrlOverride.trim().isEmpty
        ? configuredBaseUrl
        : apiBaseUrlOverride.trim();

    return AppConfiguration(
      environment: environment,
      apiBaseUrl: _withoutTrailingSlash(apiBaseUrl),
    );
  }

  static String _withoutTrailingSlash(String value) {
    return value.replaceFirst(RegExp(r'/+$'), '');
  }
}
