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
import 'package:go_router/go_router.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/core/design_system/octogear_theme.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/authentication/presentation/controllers/registration_cities_controller.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/customer_profile/presentation/controllers/customer_profile_controller.dart';
import 'package:octogear/features/customer_profile/presentation/screens/customer_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_fixtures.dart';

class _Locale extends AppLocaleController {
  _Locale(this.locale);
  final AppLocale locale;
  @override
  AppLocale build() => locale;
}

class _Cities extends RegistrationCitiesController {
  _Cities() : super('');
  @override
  Future<RegistrationCitiesState> build() async =>
      const RegistrationCitiesState(
        page: AppCityPage(
          items: [
            AppCity(id: 1, name: 'Riyadh'),
            AppCity(id: 2, name: 'Jeddah'),
          ],
          page: 1,
          lastPage: 1,
        ),
      );
}

class _Loader extends AssetLoader {
  const _Loader(this.translations);
  final Map<String, Map<String, dynamic>> translations;
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      translations[locale.languageCode]!;
}

class _App extends StatelessWidget {
  const _App(this.router, this.scale);
  final GoRouter router;
  final double scale;
  @override
  Widget build(BuildContext context) => MaterialApp.router(
    routerConfig: router,
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
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final translations = <String, Map<String, dynamic>>{};
  final boundaryKey = GlobalKey();
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
    FakeProfileRepository repo, {
    bool arabic = false,
    double scale = 1,
  }) async {
    await tester.binding.setSurfaceSize(Size(scale == 1 ? 390 : 320, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      initialLocation: '/customer/more/profile',
      routes: [
        GoRoute(
          path: '/customer/more',
          builder: (_, _) => Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                final session = ref
                    .watch(sessionControllerProvider)
                    .asData
                    ?.value;
                return Text(
                  session is AuthenticatedSession
                      ? '${session.user.fullName} / ${session.user.city?.name}'
                      : 'Signed out',
                );
              },
            ),
          ),
          routes: [
            GoRoute(
              path: 'profile',
              builder: (_, _) => RepaintBoundary(
                key: boundaryKey,
                child: const Scaffold(
                  body: SafeArea(child: CustomerProfileScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(ProfileSession.new),
          customerProfileRepositoryProvider.overrideWithValue(repo),
          registrationCitiesProvider('').overrideWith(_Cities.new),
          appLocaleProvider.overrideWith(
            () => _Locale(arabic ? AppLocale.arabic : AppLocale.english),
          ),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('ar'), Locale('en')],
          startLocale: Locale(arabic ? 'ar' : 'en'),
          path: 'assets/translations',
          saveLocale: false,
          assetLoader: _Loader(translations),
          child: _App(router, scale),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('profile-save')));
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'only name and city are editable; save updates profile and More',
    (tester) async {
      final repo = FakeProfileRepository();
      await pump(tester, repo);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(
        tester
            .widget<SelectableText>(find.byKey(const Key('profile-mobile')))
            .data,
        profileUser.mobile,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('profile-save')))
            .onPressed,
        isNull,
      );
      await tester.enterText(
        find.byKey(const Key('profile-full-name')),
        'Updated Name',
      );
      await tester.tap(find.byKey(const Key('registration-city-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('registration-city-2')));
      await tester.pumpAndSettle();
      await save(tester);
      expect(repo.commands.single.fullName, 'Updated Name');
      expect(repo.commands.single.cityId, 2);
      expect(find.text('Your profile has been updated.'), findsOneWidget);
      await tester.ensureVisible(find.byType(BackButtonIcon));
      await tester.tap(find.byType(BackButtonIcon));
      await tester.pumpAndSettle();
      expect(find.text('Updated Name / Jeddah'), findsOneWidget);
    },
  );

  testWidgets(
    'invalid names never submit; API failure retains draft and retry saves',
    (tester) async {
      final repo = FakeProfileRepository()
        ..onUpdate = (_) async => throw const ApiFailure(
          type: ApiFailureType.validation,
          fieldErrors: {
            'full_name': ['Please check this name.'],
          },
        );
      await pump(tester, repo);
      await tester.enterText(find.byKey(const Key('profile-full-name')), '   ');
      await save(tester);
      expect(repo.commands, isEmpty);
      expect(find.text('Enter your full name.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('profile-full-name')),
        'Updated Name',
      );
      await save(tester);
      expect(find.text('Please check this name.'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('profile-full-name')))
            .controller!
            .text,
        'Updated Name',
      );
      expect(repo.commands, hasLength(1));
      repo.onUpdate = null;
      await save(tester);
      expect(repo.commands, hasLength(2));
      expect(find.text('Your profile has been updated.'), findsOneWidget);
    },
  );

  testWidgets('Back keeps the draft until discard is confirmed', (
    tester,
  ) async {
    final repo = FakeProfileRepository();
    await pump(tester, repo);
    await tester.enterText(
      find.byKey(const Key('profile-full-name')),
      'Unsaved',
    );
    await tester.tap(find.byType(BackButtonIcon));
    await tester.pumpAndSettle();
    expect(find.text('Discard your changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('profile-full-name')))
          .controller!
          .text,
      'Unsaved',
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard changes'));
    await tester.pumpAndSettle();
    expect(find.text('Original Name / Riyadh'), findsOneWidget);
    expect(repo.commands, isEmpty);
  });

  testWidgets('pending save disables edits and duplicate submissions', (
    tester,
  ) async {
    final pending = Completer<AppUser>();
    final repo = FakeProfileRepository()..onUpdate = (_) => pending.future;
    await pump(tester, repo);
    await tester.enterText(
      find.byKey(const Key('profile-full-name')),
      'Updated Name',
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('profile-save')));
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pump();
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const Key('profile-full-name')),
              matching: find.byType(TextField),
            ),
          )
          .readOnly,
      true,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('profile-save')))
          .onPressed,
      isNull,
    );
    expect(repo.commands, hasLength(1));
    pending.complete(savedProfile(repo.commands.single));
    await tester.pumpAndSettle();
  });

  for (final arabic in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('profile layout is usable arabic=$arabic scale=$scale', (
        tester,
      ) async {
        await pump(
          tester,
          FakeProfileRepository(),
          arabic: arabic,
          scale: scale,
        );
        expect(tester.takeException(), isNull);
        if (scale == 1) {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await Directory('build').create(recursive: true);
            await File(
              'build/profile-edit-${arabic ? 'ar' : 'en'}.png',
            ).writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.ensureVisible(find.byKey(const Key('profile-save')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
