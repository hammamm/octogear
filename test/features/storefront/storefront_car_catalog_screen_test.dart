import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/core/design_system/octogear_theme.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/storefront/domain/entities/storefront_car_catalog.dart';
import 'package:octogear/features/storefront/presentation/controllers/storefront_car_catalog_providers.dart';
import 'package:octogear/features/storefront/presentation/screens/customer_store_car_screen.dart';
import 'package:octogear/features/storefront/presentation/widgets/storefront_component_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/car_catalog_fixtures.dart';

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

  Future<void> pump(
    WidgetTester tester,
    FakeCarCatalogRepository repository, {
    bool arabic = false,
    double textScale = 1,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storefrontCarCatalogRepositoryProvider.overrideWithValue(repository),
          appLocaleProvider.overrideWith(
            arabic ? _ArabicLocale.new : _EnglishLocale.new,
          ),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('ar'), Locale('en')],
          startLocale: Locale(arabic ? 'ar' : 'en'),
          path: 'assets/translations',
          saveLocale: false,
          assetLoader: _Translations(translations),
          child: _App(textScale: textScale),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('shows gallery fallback, car details and priced stock cards', (
    tester,
  ) async {
    await pump(tester, FakeCarCatalogRepository());
    await tester.pumpAndSettle();
    expect(find.text('Camry'), findsOneWidget);
    expect(find.text('2020'), findsOneWidget);
    expect(find.text('No car photos yet'), findsOneWidget);
    await _reveal(tester, find.byType(StorefrontComponentCard).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('520.25'), findsOneWidget);
    expect(find.text('Alternator'), findsOneWidget);
    expect(find.textContaining('In stock'), findsOneWidget);
    await _reveal(tester, find.text('Part description'));
    await tester.tap(find.text('Part description'));
    await tester.pumpAndSettle();
    expect(find.text('Tested original part from this car.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'car stays visible when parts fail, retry shows a truthful empty state',
    (tester) async {
      final repository = FakeCarCatalogRepository()
        ..components = (_, _) async =>
            throw const ApiFailure(type: ApiFailureType.noConnection);
      await pump(tester, repository);
      await tester.pumpAndSettle();
      expect(find.text('Camry'), findsOneWidget);
      await _reveal(tester, find.text('Retry'));
      repository.components = (_, _) async =>
          catalogPage(1, last: true, parts: []);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('No parts listed yet'), findsOneWidget);
      expect(repository.calls.length, 2);
    },
  );

  testWidgets('not found has a clear recovery action', (tester) async {
    final repository = FakeCarCatalogRepository()
      ..details = (_) async =>
          throw const ApiFailure(type: ApiFailureType.notFound);
    await pump(tester, repository);
    await tester.pumpAndSettle();
    expect(find.text('Car or parts unavailable'), findsOneWidget);
    expect(find.text('Back to stores'), findsOneWidget);
    expect(find.byType(StorefrontComponentCard), findsNothing);
  });

  testWidgets(
    'loading is visible while either independent request is pending',
    (tester) async {
      final car = Completer<StorefrontCarDetails>();
      final parts = Completer<StorefrontComponentsPage>();
      final repository = FakeCarCatalogRepository();
      repository.details = (_) => car.future;
      repository.components = (_, _) => parts.future;
      await pump(tester, repository);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      car.complete(catalogCar);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Camry'), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      parts.complete(catalogPage(1, last: true));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'Arabic RTL at large text keeps car, conditions and stock readable',
    (tester) async {
      final repository = FakeCarCatalogRepository()
        ..components = (_, _) async => catalogPage(
          1,
          last: true,
          parts: [catalogPart(1, stock: 0, warranty: 0)],
        );
      await pump(tester, repository, arabic: true, textScale: 1.8);
      await tester.pumpAndSettle();
      expect(
        Directionality.of(
          tester.element(find.byType(CustomerStoreCarScreen)),
        ).name,
        'rtl',
      );
      await _reveal(tester, find.text('تقرير حالة السيارة'));
      await tester.tap(find.text('تقرير حالة السيارة'));
      await tester.pumpAndSettle();
      expect(find.text('حالة جيدة'), findsOneWidget);
      await _reveal(tester, find.text('غير متوفر حالياً'));
      await tester.pumpAndSettle();
      expect(find.text('غير متوفر حالياً'), findsOneWidget);
      await _reveal(tester, find.text('بدون ضمان'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'load more keeps existing cards and appends the remaining parts',
    (tester) async {
      await pump(tester, FakeCarCatalogRepository());
      await tester.pumpAndSettle();
      await _reveal(tester, find.text('Load more parts'));
      await tester.tap(find.text('Load more parts'));
      await tester.pumpAndSettle();
      await _reveal(tester, find.text('Starter Motor'));
      expect(find.text('Starter Motor'), findsOneWidget);
      expect(find.text('Load more parts'), findsNothing);
    },
  );
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  for (var step = 0; step < 25; step++) {
    if (finder.hitTestable().evaluate().isNotEmpty) return;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -180));
    await tester.pump(const Duration(milliseconds: 300));
  }
  expect(finder.hitTestable(), findsWidgets);
}

class _App extends StatelessWidget {
  const _App({required this.textScale});
  final double textScale;
  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: OctoGearTheme.lightTheme,
    locale: context.locale,
    supportedLocales: context.supportedLocales,
    localizationsDelegates: context.localizationDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: const Scaffold(
      body: SafeArea(child: CustomerStoreCarScreen(storeId: 14, carId: 7)),
    ),
  );
}

class _EnglishLocale extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.english;
}

class _ArabicLocale extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.arabic;
}

class _Translations extends AssetLoader {
  const _Translations(this.translations);
  final Map<String, Map<String, dynamic>> translations;
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      translations[locale.languageCode]!;
}
