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
import 'package:octogear/features/part_requests/domain/entities/part_request.dart';
import 'package:octogear/features/part_requests/presentation/controllers/part_request_providers.dart';
import 'package:octogear/features/part_requests/presentation/screens/request_part_screen.dart';
import 'package:octogear/features/part_requests/presentation/services/part_request_photo_picker.dart';
import 'package:octogear/features/storefront/presentation/controllers/storefront_car_catalog_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storefront/support/car_catalog_fixtures.dart';
import 'part_request_test.dart' show FakeRequestRepository, requestKey;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final translations = <String, Map<String, dynamic>>{};
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    for (final locale in ['ar', 'en']) {
      translations[locale] =
          jsonDecode(
                await rootBundle.loadString('assets/translations/$locale.json'),
              )
              as Map<String, dynamic>;
    }
  });

  Future<void> pump(
    WidgetTester tester,
    FakeRequestRepository repository, {
    bool arabic = false,
    double scale = 1,
    FakePhotoPicker? picker,
  }) async {
    await tester.binding.setSurfaceSize(const Size(360, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          partRequestRepositoryProvider.overrideWithValue(repository),
          storefrontCarCatalogRepositoryProvider.overrideWithValue(
            FakeCarCatalogRepository(),
          ),
          partRequestPhotoPickerProvider.overrideWithValue(
            picker ?? FakePhotoPicker(),
          ),
          appLocaleProvider.overrideWith(arabic ? _Arabic.new : _English.new),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('ar'), Locale('en')],
          startLocale: Locale(arabic ? 'ar' : 'en'),
          path: 'assets/translations',
          saveLocale: false,
          assetLoader: _Translations(translations),
          child: _App(scale: scale),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'customer sets quantity, notes and photo and gets a confirmed reference',
    (tester) async {
      final repository = FakeRequestRepository();
      final picker = FakePhotoPicker()
        ..photo = PartRequestPhoto(
          bytes: base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAF/gL+9/3K8QAAAABJRU5ErkJggg==',
          ),
          mimeType: 'image/png',
        );
      await pump(tester, repository, picker: picker);
      expect(find.text('Alternator'), findsOneWidget);
      expect(find.text('Al Faris'), findsOneWidget);
      await _reveal(tester, find.byTooltip('Increase quantity'));
      await tester.tap(find.byTooltip('Increase quantity'));
      await _reveal(tester, find.byKey(const ValueKey('request-notes')));
      await tester.enterText(
        find.byKey(const ValueKey('request-notes')),
        'Please check the connector',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _reveal(tester, find.text('Add a photo'));
      await tester.tap(find.text('Add a photo'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Attached part photo'), findsOneWidget);
      await _reveal(tester, find.byKey(const ValueKey('send-part-request')));
      await tester.tap(find.byKey(const ValueKey('send-part-request')));
      await tester.pumpAndSettle();
      expect(repository.commands, hasLength(1));
      expect(repository.commands.single.quantity, 2);
      expect(repository.commands.single.notes, 'Please check the connector');
      expect(repository.commands.single.photo, isNotNull);
      expect(find.text('Request sent'), findsOneWidget);
      expect(find.text('Request #42'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'stock-bounded validation stops invalid quantity before submission',
    (tester) async {
      final repository = FakeRequestRepository();
      await pump(tester, repository);
      await _reveal(tester, find.byKey(const ValueKey('request-quantity')));
      await tester.enterText(
        find.byKey(const ValueKey('request-quantity')),
        '3',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _reveal(tester, find.byKey(const ValueKey('send-part-request')));
      await tester.tap(find.byKey(const ValueKey('send-part-request')));
      await tester.pumpAndSettle();
      expect(repository.commands, isEmpty);
      expect(find.text('Enter a quantity between 1 and 2.'), findsOneWidget);
    },
  );

  testWidgets(
    'uncertain submission locks edits and explicitly retries without duplicate command',
    (tester) async {
      final pending = Completer<PartRequestReceipt>();
      final repository = FakeRequestRepository()
        ..onSubmit = (_) => pending.future;
      await pump(tester, repository);
      await _reveal(tester, find.byKey(const ValueKey('send-part-request')));
      await tester.tap(find.byKey(const ValueKey('send-part-request')));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('send-part-request')),
            )
            .onPressed,
        isNull,
      );
      pending.completeError(const ApiFailure(type: ApiFailureType.timeout));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('request-notes')))
            .enabled,
        isFalse,
      );
      repository.onSubmit = null;
      await _reveal(tester, find.text('Retry the same request'));
      await tester.tap(find.text('Retry the same request'));
      await tester.pumpAndSettle();
      expect(repository.commands, hasLength(2));
      expect(repository.commands.first, same(repository.commands.last));
      expect(find.text('Request sent'), findsOneWidget);
    },
  );

  testWidgets(
    'Arabic large text stays usable and accepts Arabic quantity digits',
    (tester) async {
      final repository = FakeRequestRepository();
      await pump(tester, repository, arabic: true, scale: 1.8);
      expect(
        Directionality.of(tester.element(find.byType(RequestPartScreen))).name,
        'rtl',
      );
      await _reveal(tester, find.byKey(const ValueKey('request-quantity')));
      await tester.enterText(
        find.byKey(const ValueKey('request-quantity')),
        '٢',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _reveal(tester, find.byKey(const ValueKey('send-part-request')));
      await tester.tap(find.byKey(const ValueKey('send-part-request')));
      await tester.pumpAndSettle();
      expect(repository.commands.single.quantity, 2);
      expect(find.text('تم إرسال الطلب'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('picker failure gives an actionable error without sending', (
    tester,
  ) async {
    final repository = FakeRequestRepository();
    final picker = FakePhotoPicker()..fails = true;
    await pump(tester, repository, picker: picker);
    await _reveal(tester, find.text('Add a photo'));
    await tester.tap(find.text('Add a photo'));
    await tester.pumpAndSettle();
    expect(find.textContaining("We couldn't use that photo"), findsOneWidget);
    expect(repository.commands, isEmpty);
  });
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 45; i++) {
    if (finder.hitTestable().evaluate().isNotEmpty) return;
    await tester.drag(find.byType(ListView), const Offset(0, -180));
    await tester.pump(const Duration(milliseconds: 300));
  }
  expect(finder.hitTestable(), findsWidgets);
}

class FakePhotoPicker implements PartRequestPhotoPicker {
  PartRequestPhoto? photo;
  bool fails = false;
  @override
  Future<PartRequestPhoto?> recover() async => null;
  @override
  Future<PartRequestPhoto?> pick() async {
    if (fails) throw const FormatException('Invalid photo');
    return photo;
  }
}

class _App extends StatelessWidget {
  const _App({required this.scale});
  final double scale;
  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: OctoGearTheme.lightTheme,
    locale: context.locale,
    supportedLocales: context.supportedLocales,
    localizationsDelegates: context.localizationDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: const Scaffold(
      body: SafeArea(child: RequestPartScreen(requestKey: requestKey)),
    ),
  );
}

class _English extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.english;
}

class _Arabic extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.arabic;
}

class _Translations extends AssetLoader {
  const _Translations(this.values);
  final Map<String, Map<String, dynamic>> values;
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      values[locale.languageCode]!;
}
