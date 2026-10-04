import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/configuration/api_configuration_loader.dart';
import 'package:octogear/core/configuration/app_configuration.dart';

void main() {
  test('parses explicit names and aliases, rejects unknown environments', () {
    for (final name in ['development', 'dev', ' DEV ']) {
      expect(AppEnvironment.parse(name), AppEnvironment.development);
    }
    expect(AppEnvironment.parse('staging'), AppEnvironment.staging);
    expect(AppEnvironment.parse('production'), AppEnvironment.production);
    expect(AppEnvironment.parse('prod'), AppEnvironment.production);
    expect(() => AppEnvironment.parse('stagin'), throwsArgumentError);
    expect(() => AppEnvironment.parse(''), throwsArgumentError);
  });

  test('build argument selects the requested environment', () {
    const selected = String.fromEnvironment(
      'OCTOGEAR_ENV',
      defaultValue: 'development',
    );
    expect(AppEnvironment.fromDartDefines(), AppEnvironment.parse(selected));
  });

  test(
    'development uses the manual HTTP URL without remote or cache access',
    () async {
      final result = await _manual(
        AppEnvironment.development,
        development: ' http://192.168.1.100:8000/api/// ',
        production: 'https://production.test/api',
      ).load();
      expect(result.environment, AppEnvironment.development);
      expect(result.apiBaseUrl, 'http://192.168.1.100:8000/api');
    },
  );

  test(
    'production uses its manual HTTPS URL without remote or cache access',
    () async {
      final result = await _manual(
        AppEnvironment.production,
        development: 'http://192.168.1.100:8000/api',
        production: ' https://production.test/api/ ',
      ).load();
      expect(result.environment, AppEnvironment.production);
      expect(result.apiBaseUrl, 'https://production.test/api');
    },
  );

  test(
    'manual values must be valid and never fall back to another source',
    () async {
      for (final environment in [
        AppEnvironment.development,
        AppEnvironment.production,
      ]) {
        for (final invalid in [
          '',
          'no-url',
          'https://example.test',
          'https://user:secret@example.test/api',
          'https://example.test/api?token=x',
          'ftp://example.test/api',
        ]) {
          await expectLater(
            _manual(
              environment,
              development: invalid,
              production: invalid,
            ).load(),
            throwsA(isA<LocalApiConfigurationUnavailable>()),
          );
        }
      }
      await expectLater(
        _manual(
          AppEnvironment.production,
          production: 'http://production.test/api',
        ).load(),
        throwsA(isA<LocalApiConfigurationUnavailable>()),
      );
    },
  );

  test('staging ignores manual URLs and fetches the remote URL', () async {
    final source = _Source();
    final cache = _Cache();
    final result = await ApiConfigurationLoader(
      source: () => source,
      cache: cache,
      environment: AppEnvironment.staging,
      developmentUrl: 'http://local.test/api',
      productionUrl: 'https://prod.test/api',
    ).load();
    expect(result.apiBaseUrl, 'https://staging.test/api');
    expect(source.fetched, AppEnvironment.staging);
    expect(cache.saved, ('staging', 'https://staging.test/api'));
  });
}

ApiConfigurationLoader _manual(
  AppEnvironment environment, {
  String development = '',
  String production = '',
}) => ApiConfigurationLoader(
  environment: environment,
  developmentUrl: development,
  productionUrl: production,
  source: () =>
      throw StateError('Manual environments must not create Remote Config'),
  cache: _ForbiddenCache(),
);

class _ForbiddenCache implements ApiConfigurationCache {
  @override
  String? readApiBaseUrl(String environment) =>
      throw StateError('Unexpected cache read');
  @override
  Future<void> saveApiBaseUrl(String environment, String value) =>
      throw StateError('Unexpected cache write');
}

class _Cache implements ApiConfigurationCache {
  (String, String)? saved;
  @override
  String? readApiBaseUrl(String environment) => null;
  @override
  Future<void> saveApiBaseUrl(String environment, String value) async {
    saved = (environment, value);
  }
}

class _Source implements ApiConfigurationSource {
  AppEnvironment? fetched;
  @override
  Future<void> fetch(AppEnvironment environment) async {
    fetched = environment;
  }

  @override
  String get apiBaseUrl => 'https://staging.test/api';
}
