import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'package:octogear/features/authentication/domain/use_cases/get_registration_cities_use_case.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_providers.dart';
import 'package:octogear/features/authentication/presentation/widgets/registration_city_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Translations translations;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    translations = _Translations({
      for (final code in ['en', 'ar'])
        code:
            jsonDecode(
                  await rootBundle.loadString('assets/translations/$code.json'),
                )
                as Map<String, dynamic>,
    });
  });

  testWidgets(
    'opens on demand, pages, selects and retains a city after dismissal',
    (tester) async {
      final useCase = _UseCase();
      await _pump(tester, useCase, translations);
      expect(useCase.calls, isEmpty);
      await tester.tap(find.byKey(const Key('registration-city-field')));
      await tester.pumpAndSettle();
      expect(useCase.calls, [('', 1)]);
      expect(find.text('City 1'), findsOneWidget);
      await tester.tap(find.text('Load more cities'));
      await tester.pumpAndSettle();
      expect(useCase.calls, [('', 1), ('', 2)]);
      await tester.tap(find.text('City 2'));
      await tester.pumpAndSettle();
      expect(find.text('City 2'), findsOneWidget);
      await tester.tap(find.byKey(const Key('registration-city-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('City 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('debounces server search and ignores a late previous result', (
    tester,
  ) async {
    final useCase = _UseCase();
    final stale = Completer<AppCityPage>();
    useCase.handler = (query, page) => query == 'old'
        ? stale.future
        : Future.value(_page(query == 'Aden' ? 4581 : 1, page));
    await _pump(tester, useCase, translations);
    await tester.tap(find.byKey(const Key('registration-city-field')));
    await tester.pumpAndSettle();
    final search = find.byKey(const Key('registration-city-search'));
    await tester.enterText(search, 'old');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    await tester.enterText(search, 'Ad');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(search, 'Aden');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    stale.complete(_page(99, 1));
    await tester.pumpAndSettle();
    expect(useCase.calls, [('', 1), ('old', 1), ('Aden', 1)]);
    expect(find.text('City 4581'), findsOneWidget);
    expect(find.text('City 99'), findsNothing);
  });

  testWidgets(
    'initial failure has retry and an empty search has clear feedback',
    (tester) async {
      final useCase = _UseCase();
      useCase.handler = (_, _) => Future.error(Exception('offline'));
      await _pump(tester, useCase, translations);
      await tester.tap(find.byKey(const Key('registration-city-field')));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      expect(useCase.calls, hasLength(1));
      useCase.handler = (_, _) => Future.value(_page(1, 1));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('City 1'), findsOneWidget);
      useCase.handler = (_, _) async =>
          const AppCityPage(items: [], page: 1, lastPage: 1);
      await tester.enterText(
        find.byKey(const Key('registration-city-search')),
        'unknown',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.text('No cities match your search.'), findsOneWidget);
    },
  );

  for (final code in ['en', 'ar']) {
    testWidgets(
      '$code picker fits a narrow screen with keyboard and large text',
      (tester) async {
        tester.view.physicalSize = const Size(320, 844);
        tester.view.devicePixelRatio = 1;
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        addTearDown(tester.view.reset);
        await _pump(tester, _UseCase(), translations, code: code, scale: 2);
        await tester.tap(find.byKey(const Key('registration-city-field')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('registration-city-search')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<void> _pump(
  WidgetTester tester,
  _UseCase useCase,
  _Translations translations, {
  String code = 'en',
  double scale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        getRegistrationCitiesUseCaseProvider.overrideWithValue(useCase),
        appLocaleProvider.overrideWith(_Locale.new),
      ],
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        startLocale: Locale(code),
        path: 'assets/translations',
        assetLoader: translations,
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const _Form(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _Form extends StatefulWidget {
  const _Form();
  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  AppCity? city;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          child: RegistrationCityField(
            value: city,
            onChanged: (value) => setState(() => city = value),
          ),
        ),
      ),
    ),
  );
}

class _Translations extends AssetLoader {
  const _Translations(this.values);
  final Map<String, Map<String, dynamic>> values;
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      values[locale.languageCode]!;
}

class _Locale extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.english;
}

AppCityPage _page(int id, int page) => AppCityPage(
  items: [AppCity(id: id, name: 'City $id')],
  page: page,
  lastPage: 92,
);

class _UseCase implements GetRegistrationCitiesUseCase {
  final calls = <(String, int)>[];
  Future<AppCityPage> Function(String, int) handler = (_, page) async =>
      _page(page, page);
  @override
  Future<AppCityPage> call({String search = '', int page = 1}) {
    calls.add((search, page));
    return handler(search, page);
  }
}
