import 'dart:async';

import '../service/app_logger.dart';
import 'app_configuration.dart';

/// Firebase is isolated behind this boundary for deterministic startup tests.
abstract interface class ApiConfigurationSource {
  Future<void> fetch(AppEnvironment environment);
  String get apiBaseUrl;
}

/// Only validated, non-sensitive URLs belong in this cache.
abstract interface class ApiConfigurationCache {
  String? readApiBaseUrl(String environment);
  Future<void> saveApiBaseUrl(String environment, String value);
}

class ApiConfigurationUnavailable implements Exception {
  const ApiConfigurationUnavailable();
}

class LocalApiConfigurationUnavailable implements Exception {
  const LocalApiConfigurationUnavailable(this.environment);
  final AppEnvironment environment;

  @override
  String toString() =>
      'Set ${environment.name}ApiBaseUrl in '
      'lib/core/configuration/app_configuration.dart and rebuild.';
}

class ApiConfigurationLoader {
  ApiConfigurationLoader({
    required this.source,
    required this.cache,
    required this.environment,
    this.developmentUrl = AppConfiguration.developmentApiBaseUrl,
    this.productionUrl = AppConfiguration.productionApiBaseUrl,
    this.fetchTimeout = const Duration(seconds: 12),
  });

  // Laziness prevents even constructing Remote Config outside staging.
  final ApiConfigurationSource Function() source;
  final ApiConfigurationCache cache;
  final AppEnvironment environment;
  final String developmentUrl;
  final String productionUrl;
  final Duration fetchTimeout;

  Future<AppConfiguration> load() async {
    if (environment != AppEnvironment.staging) {
      final url = AppConfiguration.normalizeApiBaseUrl(
        environment == AppEnvironment.development
            ? developmentUrl
            : productionUrl,
        allowHttp: environment == AppEnvironment.development,
      );
      if (url == null) throw LocalApiConfigurationUnavailable(environment);
      return AppConfiguration(environment: environment, apiBaseUrl: url);
    }

    final savedUrl = AppConfiguration.normalizeApiBaseUrl(
      cache.readApiBaseUrl(environment.name),
    );
    ApiConfigurationSource? remoteSource;
    try {
      remoteSource = source();
      await remoteSource.fetch(environment).timeout(fetchTimeout);
    } catch (_) {
      unawaited(
        AppLogger.log(
          'Remote Config fetch unavailable; checking cached API configuration.',
          category: 'CONFIG',
        ),
      );
    }

    // The SDK may still have a previously activated value after a fetch fails.
    String? remoteUrl;
    try {
      remoteUrl = AppConfiguration.normalizeApiBaseUrl(
        remoteSource?.apiBaseUrl,
      );
    } catch (_) {
      // An unavailable SDK must not prevent use of our validated saved value.
    }
    final apiBaseUrl = remoteUrl ?? savedUrl;
    if (apiBaseUrl == null) throw const ApiConfigurationUnavailable();

    if (remoteUrl != null && remoteUrl != savedUrl) {
      try {
        await cache.saveApiBaseUrl(environment.name, remoteUrl);
      } catch (_) {
        // A disk-write failure must not discard a usable fetched destination.
        unawaited(
          AppLogger.log(
            'Could not persist API configuration for the next launch.',
            category: 'CONFIG',
          ),
        );
      }
    }
    unawaited(
      AppLogger.log(
        'API configuration ready (${remoteUrl != null ? 'Remote Config' : 'saved URL'}): $apiBaseUrl',
        category: 'CONFIG',
      ),
    );
    return AppConfiguration(environment: environment, apiBaseUrl: apiBaseUrl);
  }
}
