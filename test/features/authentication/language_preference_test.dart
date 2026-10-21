import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/core/storage/app_storage.dart';
import 'package:octogear/core/storage/storage_providers.dart';
import 'package:octogear/features/authentication/data/data_sources/language_preference_remote_data_source.dart';
import 'package:octogear/features/authentication/data/models/current_user_dto.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/authentication/domain/repositories/language_preference_repository.dart';
import 'package:octogear/features/authentication/domain/use_cases/save_language_preference_use_case.dart';
import 'package:octogear/features/authentication/presentation/controllers/language_preference_controller.dart';
import 'package:octogear/features/authentication/presentation/controllers/language_preference_providers.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/authentication/presentation/widgets/language_preference_scope.dart';

void main() {
  testWidgets('a failed account save displays a working retry action', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final repository = _Repository()..fail = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(
            () => _Session(_session('en')),
          ),
          appLocaleProvider.overrideWith(_Locale.new),
          sessionStorageProvider.overrideWithValue(_Storage()),
          saveLanguagePreferenceUseCaseProvider.overrideWithValue(
            SaveLanguagePreferenceUseCase(repository),
          ),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ar')],
          startLocale: const Locale('en'),
          path: 'assets/translations',
          assetLoader: const _Translations(),
          saveLocale: false,
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: const LanguagePreferenceScope(
                child: Scaffold(body: Text('Language settings')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold)),
    );
    await container.read(appLocaleProvider.notifier).select(AppLocale.arabic);
    await tester.pumpAndSettle();
    expect(find.byType(SnackBarAction), findsOneWidget);
    expect(repository.calls, ['first:ar']);
    repository.fail = false;
    await tester.tap(find.byType(SnackBarAction));
    await tester.pumpAndSettle();
    expect(repository.calls, ['first:ar', 'first:ar']);
    expect(
      container.read(languagePreferenceControllerProvider),
      LanguagePreferenceStatus.idle,
    );
    expect(tester.takeException(), isNull);
  });

  test('transport rejects an empty or mismatched save confirmation', () async {
    for (final data in [
      null,
      {'preferred_language': 'en'},
    ]) {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      final client = ApiClient(dio: dio, accessTokenResolver: () => 'first');
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'success': true, 'data': data},
              ),
            );
          },
        ),
      );
      await expectLater(
        LanguagePreferenceRemoteDataSource(
          client,
        ).save(language: 'ar', sessionToken: 'first'),
        throwsA(isA<Exception>()),
      );
    }
  });

  test('profile maps supported language and accepts legacy missing values', () {
    final data = <String, Object?>{
      'id': 1,
      'full_name': 'Test',
      'mobile': 'test',
      'type': 'customer',
    };
    expect(CurrentUserDto.fromJson(data).toEntity().preferredLanguage, isNull);
    for (final language in ['ar', 'en']) {
      final dto = CurrentUserDto.fromJson({
        ...data,
        'preferred_language': language,
      });
      expect(dto.toEntity().preferredLanguage, language);
      expect(dto.toCacheJson(), contains('"preferred_language":"$language"'));
    }
    expect(
      () => CurrentUserDto.fromJson({...data, 'preferred_language': 'fr'}),
      throwsFormatException,
    );
  });

  test(
    'restores server language without issuing a write for either role',
    () async {
      for (final role in AppUserRole.values) {
        final h = _Harness(_session('ar', role: role));
        await h.ready();
        expect(h.container.read(appLocaleProvider), AppLocale.arabic);
        expect(h.repository.calls, isEmpty);
        h.dispose();
      }
    },
  );

  test('a legacy account saves its current language once', () async {
    final h = _Harness(_session(null));
    addTearDown(h.dispose);
    await h.ready();
    expect(h.repository.calls, ['first:en']);
    h.session.change(_session(null));
    await _settle();
    expect(h.repository.calls, ['first:en']);
  });

  test('guest changes stay local', () async {
    final h = _Harness(const SignedOutSession());
    addTearDown(h.dispose);
    await h.ready();
    await h.select(AppLocale.arabic);
    expect(h.repository.calls, isEmpty);
  });

  test(
    'rapid selections are serialized and the latest explicit choice wins',
    () async {
      final h = _Harness(_session('en'));
      addTearDown(h.dispose);
      await h.ready();
      final pending = Completer<void>();
      h.repository.next = pending.future;
      await h.select(AppLocale.arabic);
      await h.select(AppLocale.english);
      expect(h.repository.calls, ['first:ar']);
      pending.complete();
      await _settle();
      expect(h.repository.calls, ['first:ar', 'first:en']);
      expect(h.status, LanguagePreferenceStatus.idle);
      expect(h.container.read(appLocaleProvider), AppLocale.english);
    },
  );

  test(
    'failed saves preserve local choice and require explicit retry',
    () async {
      final h = _Harness(_session('en'));
      addTearDown(h.dispose);
      await h.ready();
      h.repository.fail = true;
      await h.select(AppLocale.arabic);
      expect(h.status, LanguagePreferenceStatus.failed);
      expect(h.container.read(appLocaleProvider), AppLocale.arabic);
      await _settle();
      expect(h.repository.calls, ['first:ar']);
      h.repository.fail = false;
      h.container.read(languagePreferenceControllerProvider.notifier).retry();
      await _settle();
      expect(h.repository.calls, ['first:ar', 'first:ar']);
      expect(h.status, LanguagePreferenceStatus.idle);
    },
  );

  test(
    'late completion cannot overwrite a replacement account or queue its old choice',
    () async {
      final h = _Harness(_session('en'));
      addTearDown(h.dispose);
      await h.ready();
      final pending = Completer<void>();
      h.repository.next = pending.future;
      await h.select(AppLocale.arabic);
      await h.select(AppLocale.english);
      h.storage.token = 'second';
      h.session.change(_session('ar', id: 2));
      await _settle();
      pending.completeError(StateError('old save failed'));
      await _settle();
      expect(h.repository.calls, ['first:ar']);
      expect(h.container.read(appLocaleProvider), AppLocale.arabic);
      expect(h.status, LanguagePreferenceStatus.idle);
      await h.select(AppLocale.english);
      expect(h.repository.calls, ['first:ar', 'second:en']);
    },
  );

  test(
    'transport sends authenticated language payload and checks confirmation',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      final client = ApiClient(
        dio: dio,
        accessTokenResolver: () => 'first',
        localeResolver: () => 'ar',
      );
      RequestOptions? sent;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            sent = options;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {'preferred_language': 'ar'},
                },
              ),
            );
          },
        ),
      );
      await LanguagePreferenceRemoteDataSource(
        client,
      ).save(language: 'ar', sessionToken: 'first');
      expect(sent!.method, 'PATCH');
      expect(sent!.path, 'profile/language');
      expect(sent!.data, {'preferred_language': 'ar'});
      expect(sent!.headers['Authorization'], 'Bearer first');
      expect(sent!.headers['Accept-Language'], 'ar');
      expect(sent!.extra.values, isNot(contains('first')));
    },
  );

  test(
    'transport rejects a stale login before sending any HTTP request',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      final client = ApiClient(
        dio: dio,
        accessTokenResolver: () => 'replacement',
      );
      var sent = false;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            sent = true;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'success': true},
              ),
            );
          },
        ),
      );
      await expectLater(
        LanguagePreferenceRemoteDataSource(
          client,
        ).save(language: 'ar', sessionToken: 'old'),
        throwsA(isA<Exception>()),
      );
      expect(sent, isFalse);
    },
  );
}

AuthenticatedSession _session(
  String? language, {
  int id = 1,
  AppUserRole role = AppUserRole.customer,
}) => AuthenticatedSession(
  AppUser(
    id: id,
    fullName: 'Test',
    mobile: 'test',
    role: role,
    preferredLanguage: language,
  ),
);

Future<void> _settle() async {
  for (var i = 0; i < 4; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _Harness {
  _Harness(SessionOutcome initial) {
    container = ProviderContainer(
      overrides: [
        sessionControllerProvider.overrideWith(() => _Session(initial)),
        appLocaleProvider.overrideWith(_Locale.new),
        sessionStorageProvider.overrideWithValue(storage),
        saveLanguagePreferenceUseCaseProvider.overrideWithValue(
          SaveLanguagePreferenceUseCase(repository),
        ),
      ],
    );
    subscription = container.listen(
      languagePreferenceControllerProvider,
      (_, _) {},
    );
  }
  final repository = _Repository();
  final storage = _Storage();
  late final ProviderContainer container;
  late final ProviderSubscription<LanguagePreferenceStatus> subscription;
  _Session get session =>
      container.read(sessionControllerProvider.notifier) as _Session;
  LanguagePreferenceStatus get status =>
      container.read(languagePreferenceControllerProvider);
  Future<void> ready() async {
    await container.read(sessionControllerProvider.future);
    await _settle();
  }

  Future<void> select(AppLocale value) async {
    await container.read(appLocaleProvider.notifier).select(value);
    await _settle();
  }

  void dispose() {
    subscription.close();
    container.dispose();
  }
}

class _Session extends SessionController {
  _Session(this.initial);
  final SessionOutcome initial;
  @override
  Future<SessionOutcome> build() async => initial;
  void change(SessionOutcome value) {
    state = AsyncData(value);
  }
}

class _Locale extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.english;
  @override
  Future<void> select(AppLocale locale) async {
    state = locale;
  }
}

class _Repository implements LanguagePreferenceRepository {
  final calls = <String>[];
  Future<void>? next;
  bool fail = false;
  @override
  Future<void> save({
    required String language,
    required String sessionToken,
  }) async {
    calls.add('$sessionToken:$language');
    final pending = next;
    next = null;
    if (pending != null) await pending;
    if (fail) throw StateError('offline');
  }
}

class _Storage implements SessionStorage {
  String? token = 'first';
  @override
  String? get cachedAccessToken => token;
  @override
  Future<String?> readAccessToken() async => token;
  @override
  Future<void> saveAccessToken(String accessToken) async {
    token = accessToken;
  }

  @override
  Future<void> clearSession() async {
    token = null;
  }
}

class _Translations extends AssetLoader {
  const _Translations();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {
    'app_settings': {
      'language_save_failed': 'Could not save language to your account.',
    },
    'common': {'retry': 'Try again'},
  };
}
