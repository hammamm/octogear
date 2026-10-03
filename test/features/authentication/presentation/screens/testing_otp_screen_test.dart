import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:octogear/core/api/api_providers.dart';
import 'package:octogear/core/configuration/app_configuration.dart';
import 'package:octogear/core/design_system/octogear_theme.dart';
import 'package:octogear/features/authentication/domain/entities/saudi_mobile_number.dart';
import 'package:octogear/features/authentication/presentation/controllers/authentication_flow_controller.dart';
import 'package:octogear/features/authentication/presentation/screens/otp_verification_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final translations = <String, Map<String, dynamic>>{};
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    for (final code in ['ar', 'en']) {
      translations[code] =
          jsonDecode(
                await rootBundle.loadString('assets/translations/$code.json'),
              )
              as Map<String, dynamic>;
    }
  });
  for (final language in ['ar', 'en']) {
    for (final development in [true, false]) {
      testWidgets(
        'OTP screen testing banner language=$language development=$development',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 844));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final container = ProviderContainer(
            overrides: [
              appLocaleProvider.overrideWith(() => _Locale(language)),
              appConfigurationProvider.overrideWithValue(
                AppConfiguration(
                  environment: development
                      ? AppEnvironment.development
                      : AppEnvironment.production,
                  apiBaseUrl: 'https://example.test/api',
                ),
              ),
            ],
          );
          addTearDown(container.dispose);
          container
              .read(authenticationFlowProvider.notifier)
              .startOtp(
                SaudiMobileNumber.tryParse('500000001')!,
                testOtp: '0042',
              );
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: EasyLocalization(
                supportedLocales: const [Locale('ar'), Locale('en')],
                startLocale: Locale(language),
                path: 'assets/translations',
                saveLocale: false,
                assetLoader: _Translations(translations),
                child: Builder(
                  builder: (context) => MaterialApp(
                    theme: OctoGearTheme.lightTheme,
                    locale: context.locale,
                    supportedLocales: context.supportedLocales,
                    localizationsDelegates: context.localizationDelegates,
                    builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(textScaler: const TextScaler.linear(2)),
                      child: child!,
                    ),
                    home: const OtpVerificationScreen(),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('testing-otp-banner')),
            development ? findsOneWidget : findsNothing,
          );
          expect(
            find.text('0042'),
            development ? findsOneWidget : findsNothing,
          );
          expect(
            tester
                .widget<TextFormField>(find.byType(TextFormField))
                .controller!
                .text,
            isEmpty,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

class _Translations extends AssetLoader {
  const _Translations(this.values);
  final Map<String, Map<String, dynamic>> values;
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      values[locale.languageCode]!;
}

class _Locale extends AppLocaleController {
  _Locale(this.language);
  final String language;
  @override
  AppLocale build() => language == 'ar' ? AppLocale.arabic : AppLocale.english;
}
