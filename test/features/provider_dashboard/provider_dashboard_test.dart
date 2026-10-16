import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/core/localization/app_locale.dart';
import 'package:octogear/core/localization/app_locale_controller.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/provider_dashboard/data/data_sources/provider_dashboard_remote_data_source.dart';
import 'package:octogear/features/provider_dashboard/data/models/provider_dashboard_dto.dart';
import 'package:octogear/features/provider_dashboard/domain/entities/provider_dashboard.dart';
import 'package:octogear/features/provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import '../provider_stores/provider_stores_fixtures.dart';
import 'provider_dashboard_fixtures.dart';

void main() {
  Future<ProviderContainer> setup(FakeDashboard repository) async {
    final container = ProviderContainer(
      overrides: [
        sessionControllerProvider.overrideWith(StoreSession.new),
        appLocaleProvider.overrideWith(StoreLocale.new),
        providerDashboardRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.future);
    return container;
  }

  test(
    'dashboard preserves minor units, typed scopes and immutable collections',
    () {
      final dashboard = ProviderDashboardDto.fromJson(
        dashboardJson(storeId: 2),
      ).toEntity();
      expect(dashboard.sales.amount, 24690);
      expect(dashboard.sales.priceScale, 100);
      expect(dashboard.selectedStoreId, 2);
      expect(dashboard.period, ProviderDashboardPeriod.month);
      expect(dashboard.awaitingPayment.items.single.acceptedOfferId, 132);
      expect(() => dashboard.stores.clear(), throwsUnsupportedError);
      expect(() => dashboard.paid.items.clear(), throwsUnsupportedError);
    },
  );

  test(
    'dashboard rejects malformed scope, money, permissions and activity membership',
    () {
      for (final patch in <Map<String, dynamic>>[
        {'selected_store_id': 999},
        {'period': 'year'},
        {
          'stores': [
            {'id': 0, 'name': 'Invalid'},
          ],
        },
        {
          'stores': [
            {'id': 1, 'name': 'Duplicate'},
            {'id': 1, 'name': 'Duplicate'},
          ],
        },
        {
          'sales': {
            ...dashboardJson()['sales'] as Map<String, dynamic>,
            'amount': -1,
          },
        },
        {
          'sales': {
            ...dashboardJson()['sales'] as Map<String, dynamic>,
            'currency': 'USD',
          },
        },
        {
          'sales': {
            ...dashboardJson()['sales'] as Map<String, dynamic>,
            'price_scale': 1,
          },
        },
        {
          'sales': {
            ...dashboardJson()['sales'] as Map<String, dynamic>,
            'from': '2027-01-01T00:00:00Z',
          },
        },
        {
          'recent_orders': {
            'total': 1,
            'items': [dashboardOrderJson(storeId: 999)],
          },
        },
        {
          'recent_orders': {
            'total': 0,
            'items': [dashboardOrderJson()],
          },
        },
        {
          'attention': {
            ...dashboardJson()['attention'] as Map<String, dynamic>,
            'paid': {
              'total': 1,
              'items': [dashboardOrderJson(status: 'completed')],
            },
          },
        },
      ]) {
        expect(
          () => ProviderDashboardDto.fromJson({...dashboardJson(), ...patch}),
          throwsFormatException,
        );
      }
      for (final patch in <Map<String, dynamic>>[
        {'id': -1},
        {'total_amount': 10.5},
        {'quantity': 0},
        {'currency': 'USD'},
        {'order_type': 'other'},
        {'status': 'unknown'},
        {'created_at': 'bad'},
        {'can_chat': 'yes'},
        {'order_type': 'general', 'accepted_offer_id': null},
      ]) {
        expect(
          () => ProviderDashboardOrderDto.fromJson({
            ...dashboardOrderJson(),
            ...patch,
          }),
          throwsFormatException,
        );
      }
      for (final status in ['pending', 'completed', 'cancelled', 'rejected']) {
        expect(
          ProviderDashboardOrderDto.fromJson({
            ...dashboardOrderJson(status: status),
            'can_chat': true,
          }).value.canChat,
          isFalse,
        );
      }
    },
  );

  test(
    'remote source authenticates and verifies selected filters and activity pagination',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      addTearDown(dio.close);
      final api = ApiClient(
        dio: dio,
        accessTokenResolver: () => 'test-token',
        localeResolver: () => 'ar',
      );
      final requests = <RequestOptions>[];
      Map<String, dynamic>? badDashboard;
      Map<String, dynamic>? badOrder;
      var responsePage = 1;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            final list = options.path.endsWith('/orders');
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'message': '',
                  'data': list
                      ? [badOrder ?? dashboardOrderJson(storeId: 2)]
                      : badDashboard ??
                            dashboardJson(storeId: 2, period: 'week'),
                  if (list)
                    'meta': {
                      'current_page': responsePage,
                      'last_page': 2,
                      'per_page': 15,
                      'total': 16,
                    },
                },
              ),
            );
          },
        ),
      );
      final remote = ProviderDashboardRemoteDataSource(api);
      const query = (storeId: 2, period: ProviderDashboardPeriod.week);
      await remote.getDashboard(query);
      expect(requests.last.queryParameters, {'period': 'week', 'store_id': 2});
      expect(requests.last.headers['Authorization'], 'Bearer test-token');
      expect(requests.last.headers['Accept-Language'], 'ar');
      badDashboard = dashboardJson(storeId: 1, period: 'week');
      await expectLater(remote.getDashboard(query), throwsA(isA<ApiFailure>()));
      badDashboard = dashboardJson(storeId: 2, period: 'month');
      await expectLater(remote.getDashboard(query), throwsA(isA<ApiFailure>()));
      const activity = (storeId: 2, section: ProviderDashboardSection.paid);
      await remote.getActivity(activity);
      expect(requests.last.queryParameters, {
        'section': 'paid',
        'store_id': 2,
        'page': 1,
      });
      badOrder = dashboardOrderJson(storeId: 1);
      await expectLater(
        remote.getActivity(activity),
        throwsA(isA<ApiFailure>()),
      );
      badOrder = dashboardOrderJson(storeId: 2, status: 'completed');
      await expectLater(
        remote.getActivity(activity),
        throwsA(isA<ApiFailure>()),
      );
      badOrder = null;
      responsePage = 2;
      await expectLater(
        remote.getActivity(activity),
        throwsA(isA<ApiFailure>()),
      );
      await expectLater(
        remote.getActivity(activity, page: 0),
        throwsArgumentError,
      );
    },
  );

  test(
    'filters survive navigation and locale refresh, then reset for a new account',
    () async {
      final repository = FakeDashboard();
      final container = await setup(repository);
      final subscription = container.listen(
        providerDashboardProvider,
        (_, _) {},
      );
      await container.read(providerDashboardProvider.future);
      container.read(providerDashboardFilterProvider.notifier).selectStore(2);
      container
          .read(providerDashboardFilterProvider.notifier)
          .selectPeriod(ProviderDashboardPeriod.week);
      await container.read(providerDashboardProvider.future);
      expect(repository.queries.last, (
        storeId: 2,
        period: ProviderDashboardPeriod.week,
      ));
      await container.read(appLocaleProvider.notifier).select(AppLocale.arabic);
      await container.read(providerDashboardProvider.future);
      expect(repository.queries.last.storeId, 2);
      subscription.close();
      await container.pump();
      expect(container.read(providerDashboardFilterProvider).storeId, 2);
      (container.read(sessionControllerProvider.notifier) as StoreSession)
          .replace(
            const AuthenticatedSession(
              AppUser(
                id: 2,
                fullName: 'Second Owner',
                mobile: '+966500000002',
                role: AppUserRole.provider,
              ),
            ),
          );
      await container.pump();
      expect(container.read(providerDashboardFilterProvider), (
        storeId: null,
        period: ProviderDashboardPeriod.month,
      ));
    },
  );

  test(
    'dashboard retries only explicitly and late old-account data cannot replace the current result',
    () async {
      final repository = FakeDashboard();
      final oldResult = Completer<ProviderDashboard>();
      repository.response = (_) => oldResult.future;
      final container = await setup(repository);
      container.listen(providerDashboardProvider, (_, _) {});
      await container.pump();
      repository.response = (_) async =>
          throw const ApiFailure(type: ApiFailureType.noConnection);
      (container.read(sessionControllerProvider.notifier) as StoreSession)
          .replace(
            const AuthenticatedSession(
              AppUser(
                id: 2,
                fullName: 'Second Owner',
                mobile: '+966500000002',
                role: AppUserRole.provider,
              ),
            ),
          );
      await expectLater(
        container.read(providerDashboardProvider.future),
        throwsA(isA<ApiFailure>()),
      );
      final calls = repository.queries.length;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(repository.queries.length, calls);
      oldResult.complete(testDashboard());
      await container.pump();
      expect(container.read(providerDashboardProvider).hasError, isTrue);
      expect(container.read(providerDashboardProvider).asData, isNull);
      repository.response = (_) async => testDashboard();
      container.invalidate(providerDashboardProvider);
      expect(
        (await container.read(providerDashboardProvider.future)).sales.amount,
        24690,
      );
    },
  );

  test(
    'activity merges by identity, preserves results on pagination failure, and retries explicitly',
    () async {
      final repository = FakeDashboard();
      var failNext = true;
      repository.activityResponse = (query, page) async {
        if (page == 2 && failNext) {
          throw const ApiFailure(type: ApiFailureType.noConnection);
        }
        return ProviderDashboardActivityPage(
          items: [
            testDashboardOrder(),
            if (page == 2) testDashboardOrder(id: 32),
          ],
          page: page,
          lastPage: 2,
          total: 2,
        );
      };
      final container = await setup(repository);
      final provider = providerDashboardActivityProvider((
        storeId: null,
        section: ProviderDashboardSection.paid,
      ));
      container.listen(provider, (_, _) {});
      await container.read(provider.future);
      await container.read(provider.notifier).loadMore();
      expect(container.read(provider).requireValue.error, isA<ApiFailure>());
      expect(container.read(provider).requireValue.page.items.length, 1);
      failNext = false;
      await container.read(provider.notifier).loadMore();
      expect(
        container.read(provider).requireValue.page.items.map((item) => item.id),
        [31, 32],
      );
      expect(container.read(provider).requireValue.page.hasMore, isFalse);
    },
  );

  test('activity discards a page that completes after logout', () async {
    final repository = FakeDashboard();
    final next = Completer<ProviderDashboardActivityPage>();
    repository.activityResponse = (_, page) async => page == 2
        ? next.future
        : ProviderDashboardActivityPage(
            items: [testDashboardOrder()],
            page: 1,
            lastPage: 2,
            total: 2,
          );
    final container = await setup(repository);
    final provider = providerDashboardActivityProvider((
      storeId: null,
      section: ProviderDashboardSection.paid,
    ));
    container.listen(provider, (_, _) {});
    await container.read(provider.future);
    final request = container.read(provider.notifier).loadMore();
    (container.read(sessionControllerProvider.notifier) as StoreSession)
        .replace(const SignedOutSession());
    await expectLater(
      container.read(provider.future),
      throwsA(isA<ApiFailure>()),
    );
    next.complete(
      ProviderDashboardActivityPage(
        items: [testDashboardOrder(id: 99)],
        page: 2,
        lastPage: 2,
        total: 2,
      ),
    );
    await request;
    expect(container.read(provider).hasError, isTrue);
    expect(container.read(provider).asData, isNull);
  });
}
