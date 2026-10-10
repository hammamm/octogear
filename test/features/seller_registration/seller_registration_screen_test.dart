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
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/core/api/api_providers.dart';
import 'package:octogear/core/configuration/app_configuration.dart';
import 'package:octogear/core/design_system/octogear_theme.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/seller_registration/domain/entities/seller_application.dart';
import 'package:octogear/features/seller_registration/presentation/services/registration_document_picker.dart';
import 'package:octogear/features/seller_registration/presentation/controllers/seller_registration_controller.dart';
import 'package:octogear/features/seller_registration/presentation/screens/seller_registration_screen.dart';
import 'seller_fixtures.dart';
import 'package:octogear/features/seller_registration/domain/entities/seller_company.dart';
import 'package:octogear/features/seller_registration/domain/repositories/seller_company_repository.dart';
import 'package:octogear/features/seller_registration/presentation/controllers/seller_company_providers.dart';

const _boundary = Key('seller-preview');

class _Companies implements SellerCompanyRepository {
  final calls = <(String, int)>[];
  @override
  Future<SellerCompanyPage> fetch(String query, int page) async {
    calls.add((query, page));
    if (query.isNotEmpty) {
      return const SellerCompanyPage([SellerCompany(3, 'Honda')], false);
    }
    return page == 1
        ? const SellerCompanyPage([SellerCompany(1, 'Toyota')], true)
        : const SellerCompanyPage([SellerCompany(2, 'Ford')], false);
  }
}

class _Locale extends AppLocaleController {
  _Locale(this.arabic);
  final bool arabic;
  @override
  AppLocale build() => arabic ? AppLocale.arabic : AppLocale.english;
}

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
    FakeSellerRepository repo, {
    bool arabic = false,
    double scale = 1,
    SellerCompanyRepository? companies,
  }) async {
    await tester.binding.setSurfaceSize(Size(scale == 1 ? 390 : 320, 844));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (companies != null)
            sellerCompanyRepositoryProvider.overrideWithValue(companies),
          sessionControllerProvider.overrideWith(SellerSession.new),
          sellerRegistrationRepositoryProvider.overrideWithValue(repo),
          registrationDocumentPickerProvider.overrideWithValue(
            FakeRegistrationPicker(),
          ),
          appLocaleProvider.overrideWith(() => _Locale(arabic)),
          appConfigurationProvider.overrideWithValue(
            const AppConfiguration(
              environment: AppEnvironment.staging,
              apiBaseUrl: 'https://example.test/api',
            ),
          ),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('ar'), Locale('en')],
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
                key: _boundary,
                child: Scaffold(
                  body: SafeArea(child: SellerRegistrationScreen()),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String key) async {
    final finder = find.byKey(Key(key));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Future<void> fill(WidgetTester tester, String key, String value) async {
    final finder = find.byKey(Key(key));
    await tester.ensureVisible(finder);
    await tester.enterText(finder, value);
    await tester.pump();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('CAPTURE_SELLER_PREVIEWS')) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    scrollable.position.jumpTo(0);
    await tester.pumpAndSettle();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_boundary),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      await Directory('build/seller-previews').create(recursive: true);
      await File(
        'build/seller-previews/$name.png',
      ).writeAsBytes(data!.buffer.asUint8List());
    });
  }

  for (final arabic in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('complete seller application, Arabic=$arabic text=$scale', (
        tester,
      ) async {
        final repo = FakeSellerRepository();
        await pump(tester, repo, arabic: arabic, scale: scale);
        if (scale == 1) {
          await capture(tester, '${arabic ? 'ar' : 'en'}-business');
        }
        await tap(tester, 'seller-next');
        expect(repo.sends, 0);
        await fill(
          tester,
          'seller-commercial_registration_number',
          '1234567890',
        );
        await tap(tester, 'seller-document');
        await tap(tester, 'seller-next');
        await fill(tester, 'seller-name', 'Octo Parts');
        await fill(tester, 'seller-nick_name', 'Octo');
        await fill(
          tester,
          'seller-url_location',
          'https://maps.example.test/store',
        );
        if (scale == 1) await capture(tester, '${arabic ? 'ar' : 'en'}-store');
        await tap(tester, 'seller-next');
        await fill(tester, 'seller-mobile', '0500000002');
        await tap(tester, 'seller-next');
        expect(find.text('0042'), findsOneWidget);
        if (scale == 1) await capture(tester, '${arabic ? 'ar' : 'en'}-phone');
        await fill(tester, 'seller-code', '0042');
        await tap(tester, 'seller-next');
        if (scale == 1) await capture(tester, '${arabic ? 'ar' : 'en'}-review');
        await tap(tester, 'seller-next');
        expect(repo.submits, 1);
        expect(repo.lastDraft!.name, 'Octo Parts');
        expect(
          find.text(
            arabic ? 'طلبك قيد المراجعة' : 'Your application is under review',
          ),
          findsOneWidget,
        );
        if (scale == 1) {
          await capture(tester, '${arabic ? 'ar' : 'en'}-pending');
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'rejected application pre-fills corrections and retains the document',
    (tester) async {
      final repo = FakeSellerRepository()
        ..current = sellerApplication(
          status: SellerApplicationStatus.rejected,
          reason: 'Correct the name',
        );
      await pump(tester, repo);
      expect(find.text('Correct the name'), findsOneWidget);
      await tap(tester, 'seller-correct');
      expect(
        find.text('Your previous registration photo is attached'),
        findsOneWidget,
      );
      await tap(tester, 'seller-next');
      await fill(tester, 'seller-name', 'New Store Name');
      await tap(tester, 'seller-next');
      await tap(tester, 'seller-next');
      await tap(tester, 'seller-next');
      expect(repo.corrections, 1);
      expect(repo.sends, 0);
      expect(repo.lastDraft!.document, isNull);
      expect(repo.lastDraft!.name, 'New Store Name');
    },
  );
  testWidgets('manufacturers retain selections across pagination and search', (
    tester,
  ) async {
    final companies = _Companies();
    final repo = FakeSellerRepository()
      ..current = sellerApplication(status: SellerApplicationStatus.rejected);
    await pump(tester, repo, companies: companies, scale: 2);
    await tap(tester, 'seller-correct');
    await tap(tester, 'seller-next');
    await tap(tester, 'seller-companies');
    await tester.ensureVisible(find.text('Toyota'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toyota'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Load more'),
      100,
      scrollable: find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Scrollable),
          )
          .last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ford'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ford'));
    final search = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(TextField),
    );
    await tester.ensureVisible(search);
    await tester.pumpAndSettle();
    await tester.enterText(search, 'Honda');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    final honda = find.widgetWithText(CheckboxListTile, 'Honda');
    await tester.ensureVisible(honda);
    await tester.pumpAndSettle();
    await tester.tap(honda);
    await tester.pump();
    await tester.tap(find.text('Done · 3 selected'));
    await tester.pumpAndSettle();
    await tap(tester, 'seller-next');
    await tap(tester, 'seller-next');
    await tap(tester, 'seller-next');
    expect(repo.lastDraft!.companyIds, [1, 2, 3]);
    expect(companies.calls, [('', 1), ('', 2), ('Honda', 1)]);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'initial read failure is recoverable and does not expose a duplicate form',
    (tester) async {
      final repo = FakeSellerRepository()
        ..onLoad = () async =>
            throw const ApiFailure(type: ApiFailureType.noConnection);
      await pump(tester, repo);
      expect(find.byKey(const Key('seller-next')), findsNothing);
      repo.onLoad = null;
      await tester.tap(find.text('Check application status').first);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('seller-next')), findsOneWidget);
    },
  );
}
