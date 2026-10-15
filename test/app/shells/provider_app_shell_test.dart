import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/app/routing/app_router.dart';
import 'package:octogear/core/config/customer_features.dart';
import 'package:octogear/core/design_system/octogear_theme.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/customer_chats/domain/entities/chat.dart';
import 'package:octogear/features/customer_chats/presentation/controllers/chat_providers.dart';
import 'package:octogear/features/customer_chats/presentation/controllers/chat_realtime_providers.dart';
import 'package:octogear/features/customer_chats/presentation/screens/customer_chats_screen.dart';
import 'package:octogear/features/provider_portal/presentation/screens/provider_dashboard_screen.dart';
import 'package:octogear/features/provider_portal/presentation/screens/provider_orders_screen.dart';
import 'package:octogear/features/provider_portal/presentation/screens/provider_more_screen.dart';
import 'package:octogear/features/provider_stores/presentation/controllers/provider_stores_providers.dart';
import 'package:octogear/features/provider_stores/presentation/screens/provider_stores_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/provider_stores/provider_stores_fixtures.dart';

class _Translations extends AssetLoader {
  const _Translations(this.values);
  final Map<String, Map<String, dynamic>> values;
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      values[locale.languageCode]!;
}

class _Session extends StoreSession {
  @override
  Future<void> signOut() async => replace(const SignedOutSession());
}

class _Inbox extends ChatInboxController {
  @override
  Future<ChatInbox> build() async => const ChatInbox([], 1, 1);
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
      ('MaterialIcons', null),
    ]) {
      await (FontLoader(font.$1)..addFont(
            rootBundle.load(
              font.$2 == null
                  ? 'fonts/MaterialIcons-Regular.otf'
                  : 'assets/fonts/${font.$2}',
            ),
          ))
          .load();
    }
  });

  Future<ProviderContainer> pump(
    WidgetTester tester,
    FakeStores stores, {
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
          sessionControllerProvider.overrideWith(_Session.new),
          appLocaleProvider.overrideWith(
            () => StoreLocale(arabic ? AppLocale.arabic : AppLocale.english),
          ),
          customerStoresEnabledProvider.overrideWithValue(false),
          providerStoresRepositoryProvider.overrideWithValue(stores),
          chatInboxProvider.overrideWith(_Inbox.new),
          chatRealtimeConnectedProvider.overrideWithValue(true),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ar')],
          startLocale: Locale(arabic ? 'ar' : 'en'),
          saveLocale: false,
          path: 'assets/translations',
          assetLoader: _Translations(translations),
          child: Consumer(
            builder: (context, ref, _) => RepaintBoundary(
              key: const Key('provider-preview'),
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: OctoGearTheme.forLocale(context.locale),
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                routerConfig: ref.watch(appRouterProvider),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  }

  Future<void> tab(WidgetTester tester, String name) async {
    await tester.tap(find.byKey(Key('provider-nav-$name')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'provider starts on dashboard; orders tabs preserve selection without fetching stores',
    (tester) async {
      final stores = FakeStores();
      final container = await pump(tester, stores);
      expect(find.byType(ProviderDashboardScreen), findsOneWidget);
      expect(find.byType(ProviderStoresScreen), findsNothing);
      expect(stores.calls, 0);
      expect(find.byType(NavigationDestination), findsNWidgets(4));
      await _preview(tester, 'provider-dashboard-en');
      await tab(tester, 'orders');
      expect(find.byType(ProviderOrdersScreen), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(4));
      await tester.ensureVisible(
        find.byKey(const ValueKey('provider-orders-offers')),
      );
      await tester.tap(find.byKey(const ValueKey('provider-orders-offers')));
      await tester.pumpAndSettle();
      expect(
        find.text(translations['en']!['provider_portal']['offers_placeholder']),
        findsOneWidget,
      );
      await _preview(tester, 'provider-orders-en');
      await tab(tester, 'more');
      await tab(tester, 'orders');
      final controller = DefaultTabController.of(
        tester.element(find.byType(TabBar)),
      );
      expect(controller.index, 2);
      expect(stores.calls, 0);
      // A provider cannot enter the customer app through a direct URL.
      container.read(appRouterProvider).go('/customer/orders');
      await tester.pumpAndSettle();
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/provider',
      );
      expect(find.byType(ProviderDashboardScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'More owns store details, refresh, profile and settings; tab changes preserve child route',
    (tester) async {
      final stores = FakeStores();
      final container = await pump(tester, stores);
      await tab(tester, 'more');
      expect(find.byType(ProviderMoreScreen), findsOneWidget);
      await _preview(tester, 'provider-more-en');
      await tester.tap(find.byKey(const Key('provider-more-stores')));
      await tester.pumpAndSettle();
      expect(find.byType(ProviderStoresScreen), findsOneWidget);
      expect(find.text(store.name), findsOneWidget);
      expect(stores.calls, 1);
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/provider/more/stores',
      );
      await tester.tap(find.byTooltip('Refresh stores'));
      await tester.pumpAndSettle();
      expect(stores.calls, 2);
      await tab(tester, 'dashboard');
      await tab(tester, 'more');
      expect(find.byType(ProviderStoresScreen), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(ProviderMoreScreen), findsOneWidget);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(ProviderProfileScreen), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(ProviderSettingsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Chats keeps provider mode in the shell; store shortcut activates More',
    (tester) async {
      final stores = FakeStores();
      final container = await pump(tester, stores);
      await tab(tester, 'chats');
      final chats = tester.widget<CustomerChatsScreen>(
        find.byType(CustomerChatsScreen),
      );
      expect(chats.provider, isTrue);
      expect(chats.embeddedInShell, isTrue);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/provider/chats',
      );
      await tab(tester, 'dashboard');
      await tester.ensureVisible(
        find.byKey(const Key('provider-shortcut-stores')),
      );
      await tester.tap(find.byKey(const Key('provider-shortcut-stores')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
      expect(find.byType(ProviderStoresScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Arabic navigation and orders work at narrow width and double text scale',
    (tester) async {
      await pump(tester, FakeStores(), arabic: true, scale: 2);
      expect(
        Directionality.of(tester.element(find.byType(NavigationBar))),
        ui.TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      await _preview(tester, 'provider-dashboard-ar-large');
      await tab(tester, 'orders');
      await tester.ensureVisible(
        find.byKey(const ValueKey('provider-orders-paid')),
      );
      await tester.tap(find.byKey(const ValueKey('provider-orders-paid')));
      await tester.pumpAndSettle();
      expect(
        find.text(translations['ar']!['provider_portal']['paid_placeholder']),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tab(tester, 'more');
      expect(find.byType(ProviderMoreScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_PROVIDER_NAV_PREVIEWS')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('provider-preview')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final directory = Directory('build/provider-navigation-previews')
      ..createSync(recursive: true);
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
  });
}
