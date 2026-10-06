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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/core/design_system/octogear_theme.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/customer_orders/data/models/customer_order_dto.dart';
import 'package:octogear/features/customer_orders/domain/repositories/order_lifecycle_repository.dart';
import 'package:octogear/features/customer_orders/presentation/controllers/customer_orders_providers.dart';
import 'package:octogear/features/customer_orders/presentation/controllers/order_lifecycle_controller.dart';
import 'package:octogear/features/customer_orders/presentation/screens/customer_order_details_screen.dart';
import 'order_fixtures.dart';
import 'order_lifecycle_test.dart'
    show FakeOrderLifecycle, lifecycleJson, LifecycleEnglish;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final translations = <String, Map<String, dynamic>>{};
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    for (final code in ['ar', 'en']) {
      translations[code] =
          jsonDecode(
                await rootBundle.loadString('assets/translations/$code.json'),
              )
              as Map<String, dynamic>;
    }
    for (final name in ['NotoSansArabic', 'NotoSans']) {
      await (FontLoader(
        name == 'NotoSans' ? 'Noto Sans' : 'Noto Sans Arabic',
      )..addFont(rootBundle.load('assets/fonts/$name.ttf'))).load();
    }
  });

  Future<FakeOrderLifecycle> pump(
    WidgetTester tester, {
    String status = 'awaiting_payment',
    bool arabic = false,
    double scale = 1,
    bool uncertain = false,
  }) async {
    await tester.binding.setSurfaceSize(Size(scale == 1 ? 390 : 320, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var json = lifecycleJson(
      status: status,
      payment: ['paid', 'completed'].contains(status),
    );
    final orders = FakeOrdersRepository()
      ..onGet = (_) async => CustomerOrderDto.fromJson(json).value;
    final actions = FakeOrderLifecycle()
      ..onWrite = (action) async {
        json = lifecycleJson(
          status: action == OrderLifecycleAction.cancel
              ? 'cancelled'
              : 'completed',
          payment: action == OrderLifecycleAction.received,
        );
        if (uncertain) throw const ApiFailure(type: ApiFailureType.timeout);
      };
    final router = GoRouter(
      initialLocation: '/customer/orders/17',
      routes: [
        GoRoute(
          path: '/customer/orders/17',
          builder: (_, _) => const Scaffold(
            body: SafeArea(child: CustomerOrderDetailsScreen(orderId: 17)),
          ),
        ),
        GoRoute(
          path: '/customer/orders/17/offers/42/chat',
          builder: (_, _) => const Scaffold(body: Text('Selected store chat')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerOrdersRepositoryProvider.overrideWithValue(orders),
          orderLifecycleRepositoryProvider.overrideWithValue(actions),
          appLocaleProvider.overrideWith(
            arabic ? _Arabic.new : LifecycleEnglish.new,
          ),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('ar'), Locale('en')],
          startLocale: Locale(arabic ? 'ar' : 'en'),
          saveLocale: false,
          path: 'assets/translations',
          assetLoader: _Translations(translations),
          child: _App(router, scale),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return actions;
  }

  Future<void> reveal(WidgetTester tester, String key) async {
    await tester.scrollUntilVisible(
      find.byKey(Key(key)),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'pickup checkout cannot simulate payment and chat opens selected store',
    (tester) async {
      final actions = await pump(tester);
      expect(find.text('Store pickup'), findsOneWidget);
      expect(find.text('Delivery'), findsOneWidget);
      expect(find.text('Coming soon'), findsOneWidget);
      expect(find.text('Ahmed'), findsOneWidget);
      await reveal(tester, 'order-delivery-option');
      await tester.tap(find.byKey(const Key('order-delivery-option')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('order-delivery-coming-soon')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('order-pickup-details')), findsNothing);
      expect(find.byKey(const Key('order-pay')), findsNothing);
      expect(actions.actions, isEmpty);
      await reveal(tester, 'order-pickup-option');
      await tester.tap(find.byKey(const Key('order-pickup-option')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('order-pickup-details')), findsOneWidget);
      await reveal(tester, 'order-pay');
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('order-pay')))
            .onPressed,
        isNull,
      );
      expect(actions.actions, isEmpty);
      await reveal(tester, 'order-store-chat');
      await tester.tap(find.byKey(const Key('order-store-chat')));
      await tester.pumpAndSettle();
      expect(find.text('Selected store chat'), findsOneWidget);
    },
  );

  for (final action in OrderLifecycleAction.values) {
    testWidgets(
      '$action requires confirmation and refreshes the resulting order',
      (tester) async {
        final actions = await pump(
          tester,
          status: action == OrderLifecycleAction.cancel
              ? 'awaiting_payment'
              : 'paid',
        );
        await reveal(tester, 'order-${action.name}');
        await tester.tap(find.byKey(Key('order-${action.name}')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Go back'));
        await tester.pumpAndSettle();
        expect(actions.actions, isEmpty);
        await tester.tap(find.byKey(Key('order-${action.name}')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key('order-confirm-${action.name}')));
        await tester.pumpAndSettle();
        expect(actions.actions, [action]);
        expect(find.byKey(Key('order-${action.name}')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'timeout after completion requires read and never sends another confirmation',
    (tester) async {
      final actions = await pump(tester, status: 'paid', uncertain: true);
      await reveal(tester, 'order-received');
      await tester.tap(find.byKey(const Key('order-received')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('order-confirm-received')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('order-received')))
            .onPressed,
        isNull,
      );
      await reveal(tester, 'order-refresh-status');
      await tester.tap(find.byKey(const Key('order-refresh-status')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('order-received')), findsNothing);
      expect(actions.actions, [OrderLifecycleAction.received]);
    },
  );

  for (final ar in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'localized pickup and completed history ar=$ar scale=$scale',
        (tester) async {
          await pump(tester, arabic: ar, scale: scale);
          if (scale == 1) {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const Key('lifecycle-preview')),
            );
            await tester.runAsync(() async {
              final image = await boundary.toImage(pixelRatio: 2);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                'build/order-flow-${ar ? 'ar' : 'en'}.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          await reveal(tester, 'order-delivery-option');
          await tester.tap(find.byKey(const Key('order-delivery-option')));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('order-pay')), findsNothing);
          expect(tester.takeException(), isNull);
          if (scale == 1) {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const Key('lifecycle-preview')),
            );
            await tester.runAsync(() async {
              final image = await boundary.toImage(pixelRatio: 2);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                'build/order-flow-delivery-${ar ? 'ar' : 'en'}.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          await reveal(tester, 'order-pickup-option');
          await tester.tap(find.byKey(const Key('order-pickup-option')));
          await tester.pumpAndSettle();
          await reveal(tester, 'order-cancel');
          await tester.tap(find.byKey(const Key('order-cancel')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await pump(tester, status: 'completed', arabic: ar, scale: scale);
          expect(find.byKey(const Key('order-received')), findsNothing);
          expect(find.byKey(const Key('order-cancel')), findsNothing);
          await reveal(tester, 'order-store-chat');
          expect(
            find.text(ar ? 'تفاصيل الدفع' : 'Payment details'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

class _App extends StatelessWidget {
  const _App(this.router, this.scale);
  final GoRouter router;
  final double scale;
  @override
  Widget build(BuildContext context) => RepaintBoundary(
    key: const Key('lifecycle-preview'),
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: OctoGearTheme.forLocale(context.locale),
      locale: context.locale,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
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

class _Arabic extends AppLocaleController {
  @override
  AppLocale build() => AppLocale.arabic;
}
