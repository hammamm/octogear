import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/core/configuration/api_configuration_loader.dart';
import 'package:octogear/core/configuration/app_configuration.dart';

void main() {
  test(
    'fetches, normalizes and saves the URL before creating the API client',
    () async {
      final source = _Source(' https://new.trycloudflare.com/api/// ');
      final cache = _Cache()..values['staging'] = 'https://old.test/api';
      final configuration = await _loader(source, cache).load();
      expect(source.environment, AppEnvironment.staging);
      expect(configuration.apiBaseUrl, 'https://new.trycloudflare.com/api');
      expect(cache.values['staging'], configuration.apiBaseUrl);

      final client = ApiClient(
        configuration: configuration,
        accessTokenResolver: () => 'existing-session-token',
      );
      expect(
        client.resolveUri('profile').toString(),
        'https://new.trycloudflare.com/api/profile',
      );
      expect(
        client.resolveAuthenticatedApiUri('/api/media/orders/1'),
        Uri.parse('https://new.trycloudflare.com/api/media/orders/1'),
      );
      expect(
        client.resolveAuthenticatedApiUri('https://other.test/api/media/1'),
        isNull,
      );
      expect(
        client.authenticatedHeaders['Authorization'],
        'Bearer existing-session-token',
      );
    },
  );

  test('retains SDK activated URL when fetch fails', () async {
    final source = _Source('https://active.test/api')
      ..fetchAction = () => Future<void>.error(StateError('offline'));
    final cache = _Cache();
    expect(
      (await _loader(source, cache).load()).apiBaseUrl,
      'https://active.test/api',
    );
  });

  test(
    'invalid publication cannot overwrite last validated URL across launches',
    () async {
      final cache = _Cache();
      await _loader(_Source('https://good.test/api'), cache).load();
      for (final invalid in ['', 'http://insecure.test/api', 'not a URL']) {
        final configuration = await _loader(_Source(invalid), cache).load();
        expect(configuration.apiBaseUrl, 'https://good.test/api');
        expect(cache.values['staging'], 'https://good.test/api');
      }
    },
  );

  test(
    'fresh install with no valid remote value reports retryable failure',
    () async {
      await expectLater(
        _loader(_Source(''), _Cache()).load(),
        throwsA(isA<ApiConfigurationUnavailable>()),
      );
    },
  );

  test(
    'unavailable SDK falls back without mixing environment caches',
    () async {
      final source = _Source('')
        ..readFails = true
        ..fetchAction = () => Future<void>.error(StateError('unavailable'));
      final cache = _Cache()..values['staging'] = 'https://stage.test/api';
      expect(
        (await _loader(source, cache).load()).apiBaseUrl,
        'https://stage.test/api',
      );
      await expectLater(
        ApiConfigurationLoader(
          source: () => source,
          cache: _Cache()..values['development'] = 'https://dev.test/api',
          environment: AppEnvironment.staging,
        ).load(),
        throwsA(isA<ApiConfigurationUnavailable>()),
      );
    },
  );

  test('a stalled fetch is bounded and uses the saved URL', () async {
    final pending = Completer<void>();
    final source = _Source('')..fetchAction = () => pending.future;
    final cache = _Cache()..values['staging'] = 'https://saved.test/api';
    final configuration = await ApiConfigurationLoader(
      source: () => source,
      cache: cache,
      environment: AppEnvironment.staging,
      fetchTimeout: const Duration(milliseconds: 10),
    ).load();
    expect(configuration.apiBaseUrl, 'https://saved.test/api');
    pending.complete();
  });

  test('cache write failure does not discard a valid fetched URL', () async {
    final cache = _Cache()..writeFails = true;
    expect(
      (await _loader(
        _Source('https://fresh.test/api'),
        cache,
      ).load()).apiBaseUrl,
      'https://fresh.test/api',
    );
  });

  test(
    'next launch picks up a replacement domain, existing client stays stable',
    () async {
      final source = _Source('https://first.trycloudflare.com/api');
      final loader = _loader(source, _Cache());
      final first = ApiClient(configuration: await loader.load());
      source.value = 'https://production.test/api';
      final second = ApiClient(configuration: await loader.load());
      expect(first.resolveUri('profile').host, 'first.trycloudflare.com');
      expect(second.resolveUri('profile').host, 'production.test');
    },
  );

  test(
    'rejects missing, insecure, ambiguous or credential-bearing API URLs',
    () {
      for (final value in <String?>[
        null,
        '',
        'localhost:8000/api',
        '//host.test/api',
        'http://host.test/api',
        'ftp://host.test/api',
        'https:///api',
        'https://host.test',
        'https://host.test/api/profile',
        'https://user:secret@host.test/api',
        'https://host.test/api?token=secret',
        'https://host.test/api#fragment',
        'https://host.test/api?',
        'https://host.test/api#',
        'https://host.test:99999/api',
        'https://host.test:0/api',
        'https://bad host.test/api',
        r'https://host.test\api',
      ]) {
        expect(
          AppConfiguration.normalizeApiBaseUrl(value),
          isNull,
          reason: '$value',
        );
      }
      expect(
        AppConfiguration.normalizeApiBaseUrl('https://api.example.com/api/'),
        'https://api.example.com/api',
      );
    },
  );

  test('API client cannot silently fall back to a hard-coded destination', () {
    expect(() => ApiClient(), throwsArgumentError);
  });
}

ApiConfigurationLoader _loader(_Source source, _Cache cache) =>
    ApiConfigurationLoader(
      source: () => source,
      cache: cache,
      environment: AppEnvironment.staging,
    );

class _Source implements ApiConfigurationSource {
  _Source(this.value);
  String value;
  bool readFails = false;
  AppEnvironment? environment;
  Future<void> Function()? fetchAction;

  @override
  Future<void> fetch(AppEnvironment environment) async {
    this.environment = environment;
    await fetchAction?.call();
  }

  @override
  String get apiBaseUrl {
    if (readFails) throw StateError('SDK unavailable');
    return value;
  }
}

class _Cache implements ApiConfigurationCache {
  final values = <String, String>{};
  bool writeFails = false;

  @override
  String? readApiBaseUrl(String environment) => values[environment];

  @override
  Future<void> saveApiBaseUrl(String environment, String value) async {
    if (writeFails) throw StateError('disk full');
    values[environment] = value;
  }
}
