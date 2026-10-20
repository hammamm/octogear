import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/design_system/octogear_theme.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/authentication/presentation/screens/registration_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final translations = <String, Map<String, dynamic>>{};
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    for (final code in ['en', 'ar']) {
      translations[code] =
          jsonDecode(
                await rootBundle.loadString('assets/translations/$code.json'),
              )
              as Map<String, dynamic>;
    }
  });

  Future<void> pump(
    WidgetTester tester, {
    required String language,
    required TargetPlatform platform,
    double scale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1100);
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetPadding();
      tester.view.resetViewInsets();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appLocaleProvider.overrideWith(() => _Locale(language))],
        child: EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ar')],
          startLocale: Locale(language),
          saveLocale: false,
          path: 'assets/translations',
          assetLoader: _Translations(translations),
          child: Builder(
            builder: (context) => MaterialApp(
              theme: OctoGearTheme.forLocale(
                context.locale,
              ).copyWith(platform: platform),
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: const RegistrationScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  ScrollPosition position(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable).first).position;

  for (final language in ['en', 'ar']) {
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      testWidgets(
        '$language $platform stays fixed until resized or keyboard opens',
        (tester) async {
          await pump(tester, language: language, platform: platform);
          expect(position(tester).maxScrollExtent, 0);
          expect(
            position(tester).physics.shouldAcceptUserOffset(position(tester)),
            false,
          );
          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -150),
          );
          await tester.pumpAndSettle();
          expect(position(tester).pixels, 0);
          expect(find.byType(FilledButton).hitTestable(), findsOneWidget);

          tester.view.physicalSize = const Size(390, 420);
          await tester.pumpAndSettle();
          expect(position(tester).maxScrollExtent, greaterThan(0));
          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -200),
          );
          await tester.pumpAndSettle();
          expect(position(tester).pixels, greaterThan(0));
          await tester.ensureVisible(find.byType(FilledButton));
          await tester.pumpAndSettle();
          expect(find.byType(FilledButton).hitTestable(), findsOneWidget);

          tester.view.physicalSize = const Size(390, 1100);
          await tester.pumpAndSettle();
          expect(position(tester).maxScrollExtent, 0);
          expect(position(tester).pixels, 0);

          await tester.enterText(find.byType(TextFormField), 'Test Name');
          tester.view.viewInsets = const FakeViewPadding(bottom: 650);
          await tester.pumpAndSettle();
          expect(position(tester).maxScrollExtent, greaterThan(0));
          await tester.ensureVisible(find.byType(FilledButton));
          await tester.pumpAndSettle();
          expect(find.byType(FilledButton).hitTestable(), findsOneWidget);
          tester.view.resetViewInsets();
          await tester.pumpAndSettle();
          expect(position(tester).maxScrollExtent, 0);
          expect(find.text('Test Name'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      '$language enlarged text remains reachable on a narrow screen',
      (tester) async {
        await pump(
          tester,
          language: language,
          platform: TargetPlatform.android,
          scale: 2,
        );
        tester.view.physicalSize = const Size(320, 640);
        await tester.pumpAndSettle();
        expect(position(tester).maxScrollExtent, greaterThan(0));
        await tester.ensureVisible(find.byType(FilledButton));
        await tester.pumpAndSettle();
        expect(find.byType(FilledButton).hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _Locale extends AppLocaleController {
  _Locale(this.language);
  final String language;
  @override
  AppLocale build() => language == 'ar' ? AppLocale.arabic : AppLocale.english;
}

class _Translations extends AssetLoader {
  const _Translations(this.values);
  final Map<String, Map<String, dynamic>> values;
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      values[locale.languageCode]!;
}
