import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:octogear/app/configuration_bootstrap.dart';
import 'package:octogear/core/configuration/api_configuration_loader.dart';
import 'package:octogear/core/configuration/app_configuration.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final translations = <String, Map<String, dynamic>>{};
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    for (final language in ['ar', 'en']) {
      translations[language] =
          jsonDecode(
                await rootBundle.loadString(
                  'assets/translations/$language.json',
                ),
              )
              as Map<String, dynamic>;
    }
  });

  for (final language in ['ar', 'en']) {
    testWidgets(
      'invalid manual URL blocks startup without network retry in $language',
      (tester) async {
        var appBuilds = 0;
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('ar'), Locale('en')],
            startLocale: Locale(language),
            path: 'assets/translations',
            saveLocale: false,
            assetLoader: _Translations(translations),
            child: ConfigurationBootstrap(
              loadConfiguration: () async =>
                  throw const LocalApiConfigurationUnavailable(
                    AppEnvironment.production,
                  ),
              builder: (_) {
                appBuilds++;
                return const SizedBox();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(appBuilds, 0);
        expect(
          find.text(
            translations[language]!['startup']['invalid_configuration']
                as String,
          ),
          findsOneWidget,
        );
        expect(find.byType(FilledButton), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('gates API tree, handles failure, retries in $language', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      var request = Completer<AppConfiguration>();
      var loads = 0;
      var appBuilds = 0;
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('ar'), Locale('en')],
          startLocale: Locale(language),
          path: 'assets/translations',
          saveLocale: false,
          assetLoader: _Translations(translations),
          child: ConfigurationBootstrap(
            loadConfiguration: () {
              loads++;
              return request.future;
            },
            builder: (configuration) {
              appBuilds++;
              return const MaterialApp(home: Text('API tree ready'));
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(loads, 1);
      expect(appBuilds, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      request.completeError(const ApiConfigurationUnavailable());
      await tester.pumpAndSettle();
      expect(appBuilds, 0);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(
        find.text(translations[language]!['startup']['unavailable'] as String),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      request = Completer<AppConfiguration>();
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(loads, 2);
      expect(find.byType(FilledButton), findsNothing);
      expect(appBuilds, 0);
      request.complete(
        const AppConfiguration(
          environment: AppEnvironment.development,
          apiBaseUrl: 'https://configured.test/api',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('API tree ready'), findsOneWidget);
      expect(loads, 2);
      expect(tester.takeException(), isNull);
    });
  }
}

class _Translations extends AssetLoader {
  const _Translations(this.values);
  final Map<String, Map<String, dynamic>> values;

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      values[locale.languageCode]!;
}
