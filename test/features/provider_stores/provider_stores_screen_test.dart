import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:octogear/features/provider_stores/presentation/screens/provider_stores_screen.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/core/design_system/octogear_theme.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/provider_stores/domain/entities/provider_store.dart';
import 'package:octogear/features/provider_stores/presentation/controllers/provider_stores_providers.dart';
import 'provider_stores_fixtures.dart';

class _Translations extends AssetLoader {
  const _Translations(this.values);
  final Map<String, Map<String, dynamic>> values;
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      values[locale.languageCode]!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final translations = <String, Map<String, dynamic>>{};
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    for (final code in ['en', 'ar']) {
      translations[code] = jsonDecode(
        await rootBundle.loadString('assets/translations/$code.json'),
      );
    }
    for (final font in [
      ('Noto Sans', 'NotoSans.ttf'),
      ('Noto Sans Arabic', 'NotoSansArabic.ttf'),
    ]) {
      await (FontLoader(
        font.$1,
      )..addFont(rootBundle.load('assets/fonts/${font.$2}'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  Future<void> pump(
    WidgetTester tester,
    FakeStores repository, {
    bool arabic = false,
    double scale = 1,
  }) async {
    await tester.binding.setSurfaceSize(Size(scale == 1 ? 390 : 320, 844));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          providerStoresRepositoryProvider.overrideWithValue(repository),
          sessionControllerProvider.overrideWith(StoreSession.new),
          appLocaleProvider.overrideWith(
            () => StoreLocale(arabic ? AppLocale.arabic : AppLocale.english),
          ),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ar')],
          startLocale: Locale(arabic ? 'ar' : 'en'),
          saveLocale: false,
          path: 'assets/translations',
          assetLoader: _Translations(translations),
          child: Builder(
            builder: (context) => MaterialApp(
              theme: OctoGearTheme.forLocale(context.locale),
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: const RepaintBoundary(
                key: Key('preview'),
                child: Scaffold(body: ProviderStoresScreen()),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets(
    'loading resolves to a single store with contact details and brands',
    (tester) async {
      final pending = Completer<List<ProviderStore>>();
      final repository = FakeStores()..response = () => pending.future;
      await pump(tester, repository);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete([store]);
      await tester.pumpAndSettle();
      expect(find.text('Al Faris Parts'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text(store.mobile!), findsOneWidget);
      expect(find.text(store.location!), findsOneWidget);
      expect(find.text('Toyota'), findsOneWidget);
      expect(find.byType(ExpansionTile), findsNothing);
      expect(repository.calls, 1);
      expect(tester.takeException(), isNull);
      await _preview(tester, 'provider-store-en');
    },
  );

  testWidgets(
    'an error waits for explicit retry and empty results can refresh',
    (tester) async {
      final repository = FakeStores()
        ..response = () async =>
            throw const ApiFailure(type: ApiFailureType.noConnection);
      await pump(tester, repository);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 35));
      expect(repository.calls, 1);
      repository.response = () async => [];
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('No stores to show'), findsOneWidget);
      expect(repository.calls, 2);
      repository.response = () async => [store];
      await tester.tap(find.byTooltip('Refresh stores'));
      await tester.pumpAndSettle();
      expect(find.text(store.name), findsOneWidget);
      expect(repository.calls, 3);
    },
  );

  testWidgets('multiple stores show a list and reveal the selected details', (
    tester,
  ) async {
    final repository = FakeStores()
      ..response = () async => [
        store,
        const ProviderStore(
          id: 2,
          name: 'Second Store',
          status: ProviderStoreStatus.inactive,
          brands: [],
        ),
      ];
    await pump(tester, repository);
    await tester.pumpAndSettle();
    expect(find.byType(ExpansionTile), findsNWidgets(2));
    expect(find.text(store.mobile!), findsNothing);
    await tester.tap(find.text('Second Store'));
    await tester.pumpAndSettle();
    expect(find.text('Inactive'), findsOneWidget);
    expect(find.text('Not provided'), findsNWidgets(3));
    expect(find.text('No car brands specified'), findsOneWidget);
    expect(repository.calls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arabic supports narrow screens and enlarged text', (
    tester,
  ) async {
    final repository = FakeStores()
      ..response = () async => [
        const ProviderStore(
          id: 1,
          name: 'متجر الفارس لقطع غيار السيارات',
          status: ProviderStoreStatus.active,
          mobile: '+966511111111',
          city: 'الرياض',
          location: 'https://maps.example.test/a-long-store-location-link',
          brands: ['تويوتا', 'هوندا'],
        ),
      ];
    await pump(tester, repository, arabic: true, scale: 2);
    await tester.pumpAndSettle();
    expect(find.text('متاجري'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('متاجري'))),
      ui.TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
    await _preview(tester, 'provider-store-ar-large');
  });
}

Future<void> _preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_PROVIDER_PREVIEWS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('preview')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final directory = Directory('build/provider-store-previews')
      ..createSync(recursive: true);
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
  });
}
