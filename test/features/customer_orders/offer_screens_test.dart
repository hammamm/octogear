import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/core/design_system/octogear_theme.dart';
import 'package:octogear/features/customer_orders/presentation/controllers/customer_orders_providers.dart';
import 'package:octogear/features/customer_orders/presentation/controllers/offer_action_controller.dart';
import 'package:octogear/features/customer_orders/presentation/screens/customer_offer_details_screen.dart';
import 'package:octogear/features/customer_orders/presentation/screens/refuse_customer_offer_screen.dart';
import 'order_fixtures.dart';
import 'offer_actions_test.dart' show actionOrder, FakeOfferActions;

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
    WidgetTester tester,
    FakeOrdersRepository repo,
    FakeOfferActions actions, {
    bool refuse = false,
    bool arabic = false,
    double scale = 1,
  }) async {
    await tester.binding.setSurfaceSize(Size(scale == 1 ? 390 : 320, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      initialLocation:
          '/customer/orders/17/offers/42${refuse ? '/refuse' : ''}',
      routes: [
        GoRoute(
          path: '/customer/orders/:orderId/offers/:offerId',
          builder: (_, _) => const Scaffold(
            body: CustomerOfferDetailsScreen(orderId: 17, offerId: 42),
          ),
          routes: [
            GoRoute(
              path: 'refuse',
              builder: (_, _) => const Scaffold(
                body: RefuseCustomerOfferScreen(orderId: 17, offerId: 42),
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
          customerOrdersRepositoryProvider.overrideWithValue(repo),
          offerActionsRepositoryProvider.overrideWithValue(actions),
          appLocaleProvider.overrideWith(arabic ? _Arabic.new : _English.new),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('ar'), Locale('en')],
          startLocale: Locale(arabic ? 'ar' : 'en'),
          path: 'assets/translations',
          saveLocale: false,
          assetLoader: _Translations(translations),
          child: _App(router: router, scale: scale),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'accept asks for confirmation, then shows the confirmed selected offer',
    (tester) async {
      var current = actionOrder();
      final repo = FakeOrdersRepository()..onGet = (_) async => current;
      final actions = FakeOfferActions()
        ..onWrite = () async {
          current = actionOrder(
            status: 'awaiting_payment',
            offerStatus: 'accepted',
          );
        };
      await pump(tester, repo, actions);
      await tester.tap(find.byKey(const ValueKey('offer-accept')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(actions.accepts, 0);
      await tester.tap(find.text('Keep reviewing'));
      await tester.pumpAndSettle();
      expect(actions.accepts, 0);
      await tester.tap(find.byKey(const ValueKey('offer-accept')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Accept offer').last,
      );
      await tester.pumpAndSettle();
      expect(actions.accepts, 1);
      expect(
        find.text('Offer accepted. No payment has been made.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('offer-accept')), findsNothing);
      expect(find.byKey(const ValueKey('offer-refuse')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final withReason in [false, true]) {
    testWidgets('refusal submits with optional reason $withReason', (
      tester,
    ) async {
      var current = actionOrder();
      final repo = FakeOrdersRepository()..onGet = (_) async => current;
      final actions = FakeOfferActions()
        ..onWrite = () async {
          current = actionOrder(offerStatus: 'rejected');
        };
      await pump(tester, repo, actions, refuse: true);
      expect(actions.rejects, 0);
      if (withReason) {
        await tester.tap(find.text('Price doesn’t suit me'));
        await tester.enterText(
          find.byKey(const ValueKey('offer-refusal-note')),
          'Outside my budget',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
      }
      await tester.ensureVisible(
        find.byKey(const ValueKey('offer-confirm-refuse')),
      );
      await tester.tap(find.byKey(const ValueKey('offer-confirm-refuse')));
      await tester.pumpAndSettle();
      expect(actions.rejects, 1);
      expect(
        actions.reason,
        withReason ? 'Price doesn’t suit me\nOutside my budget' : '',
      );
      expect(find.byType(CustomerOfferDetailsScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('offer-accept')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final arabic in [false, true]) {
    for (final refuse in [false, true]) {
      testWidgets(
        'offer/refuse layout arabic=$arabic refuse=$refuse fits large text',
        (tester) async {
          await pump(
            tester,
            FakeOrdersRepository()..onGet = (_) async => actionOrder(),
            FakeOfferActions(),
            arabic: arabic,
            refuse: refuse,
            scale: 2,
          );
          final target = find.byKey(
            ValueKey(refuse ? 'offer-confirm-refuse' : 'offer-refuse'),
          );
          await tester.scrollUntilVisible(
            target,
            180,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          expect(target.hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

class _App extends StatelessWidget {
  const _App({required this.router, required this.scale});
  final GoRouter router;
  final double scale;
  @override
  Widget build(BuildContext context) => MaterialApp.router(
    routerConfig: router,
    theme: OctoGearTheme.lightTheme,
    locale: context.locale,
    localizationsDelegates: context.localizationDelegates,
    supportedLocales: context.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
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

class _English extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.english;
}

class _Arabic extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.arabic;
}
