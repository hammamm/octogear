import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/app/octogear_app.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late final Map<String, dynamic> englishTranslations;
  late final Map<String, dynamic> arabicTranslations;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    englishTranslations =
        jsonDecode(await rootBundle.loadString('assets/translations/en.json'))
            as Map<String, dynamic>;
    arabicTranslations =
        jsonDecode(await rootBundle.loadString('assets/translations/ar.json'))
            as Map<String, dynamic>;
  });

  testWidgets('renders and switches all customer destinations', (tester) async {
    await _pumpCustomerApp(
      tester,
      translations: englishTranslations,
      locale: AppLocale.english,
    );

    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Stores'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(
      find.byKey(const PageStorageKey<String>('customer-tab-home')),
      findsOneWidget,
    );

    await tester.tap(find.text('Stores'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const PageStorageKey<String>('customer-tab-stores')),
      findsOneWidget,
    );
    expect(find.text('Discover stores'), findsOneWidget);

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const PageStorageKey<String>('customer-tab-orders')),
      findsOneWidget,
    );
    expect(find.text('Your orders'), findsOneWidget);

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const PageStorageKey<String>('customer-tab-account')),
      findsOneWidget,
    );
    expect(find.text('Account details'), findsOneWidget);
  });

  testWidgets('uses Arabic labels and right-to-left layout', (tester) async {
    await _pumpCustomerApp(
      tester,
      translations: arabicTranslations,
      locale: AppLocale.arabic,
    );

    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('المتاجر'), findsOneWidget);
    expect(find.text('الطلبات'), findsOneWidget);
    expect(find.text('الحساب'), findsOneWidget);
    expect(
      Directionality.of(
        tester.element(
          find.byKey(const PageStorageKey<String>('customer-tab-home')),
        ),
      ).name,
      'rtl',
    );
  });
}

Future<void> _pumpCustomerApp(
  WidgetTester tester, {
  required Map<String, dynamic> translations,
  required AppLocale locale,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(_CustomerSessionController.new),
        appLocaleProvider.overrideWith(
          locale == AppLocale.arabic
              ? _ArabicLocaleController.new
              : _EnglishLocaleController.new,
        ),
      ],
      child: EasyLocalization(
        supportedLocales: const [Locale('ar'), Locale('en')],
        startLocale: locale.locale,
        path: 'assets/translations',
        assetLoader: _PreloadedTranslations(translations),
        saveLocale: false,
        child: const OctoGearApp(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _PreloadedTranslations extends AssetLoader {
  const _PreloadedTranslations(this.translations);

  final Map<String, dynamic> translations;

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) {
    return Future.value(translations);
  }
}

class _CustomerSessionController extends SessionController {
  @override
  Future<SessionOutcome> build() async => const AuthenticatedSession(_customer);
}

class _EnglishLocaleController extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.english;
}

class _ArabicLocaleController extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.arabic;
}

const _customer = AppUser(
  id: 1,
  fullName: 'Aisha Alharbi',
  mobile: '500000000',
  role: AppUserRole.customer,
  city: AppCity(id: 1, name: 'Riyadh'),
);
