import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/app/routing/app_routes.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/notifications/data/data_sources/notifications_remote_data_source.dart';
import 'package:octogear/features/notifications/data/models/push_notification_dto.dart';
import 'package:octogear/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:octogear/features/notifications/domain/entities/app_notification.dart';
import 'package:octogear/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:octogear/features/notifications/presentation/notification_destination.dart';

import 'notification_fixtures.dart';

void main() {
  Future<ProviderContainer> setup(
    FakeNotificationsRepository repo, {
    bool unread = false,
    AuthenticatedSession session = providerNotificationSession,
  }) async {
    final c = ProviderContainer(
      overrides: [
        notificationSessionProvider.overrideWithValue(session),
        notificationsRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(c.dispose);
    c.listen(notificationInboxProvider(unread), (_, _) {});
    await c.read(notificationInboxProvider(unread).future);
    return c;
  }

  for (final session in [notificationSession, providerNotificationSession]) {
    group('${session.user.role.name} page acknowledgements', () {
      test(
        'only the opened page is read, retaining rows and the unread cursor',
        () async {
          final rows = List.generate(
            25,
            (i) => notification(i + 1, kind: NotificationKind.offerAccepted),
          );
          final repo = FakeNotificationsRepository()..items = rows;
          repo.onPage = (_, cursor) async => NotificationPage(
            items: cursor == null
                ? repo.items.take(20).toList()
                : repo.items.skip(20).take(5).toList(),
            unreadCount: repo.items.where((n) => !n.isRead).length,
            nextCursor: cursor == null ? 'older' : null,
          );
          final c = await setup(repo, unread: true, session: session);
          final provider = notificationInboxProvider(true);
          final controller = c.read(provider.notifier);
          expect(
            repo.pageReads,
            isEmpty,
          ); // Fetching is not proof the UI displayed it.
          repo.items = [
            ...repo.items,
            notification(26),
          ]; // Unseen arrival after GET.
          expect(await controller.markOpenedPageRead(), true);
          expect(repo.pageReads.single, rows.take(20).map((n) => n.id).toSet());
          expect(c.read(provider).requireValue.page.items, hasLength(20));
          expect(
            c.read(provider).requireValue.page.items.every((n) => n.isRead),
            true,
          );
          expect(c.read(notificationCountProvider).requireValue, 6);
          await controller.loadMore();
          await controller.markOpenedPageRead();
          expect(repo.pageReads.last, rows.skip(20).map((n) => n.id).toSet());
          expect(c.read(provider).requireValue.page.items, hasLength(25));
          expect(c.read(notificationCountProvider).requireValue, 1);
          expect(repo.items.last.isRead, false);
          expect(repo.allCalls, 0);
          expect(repo.readCalls, 0);
        },
      );

      test(
        'read failures retain the page, require explicit retry and block pagination',
        () async {
          final repo = FakeNotificationsRepository()
            ..onPage = (_, _) async => NotificationPage(
              items: [notification(1)],
              unreadCount: 2,
              nextCursor: 'older',
            );
          final c = await setup(repo, session: session);
          final provider = notificationInboxProvider(false);
          final controller = c.read(provider.notifier);
          repo.failRead = true;
          expect(await controller.markOpenedPageRead(), false);
          expect(c.read(provider).requireValue.pageReadFailed, true);
          expect(c.read(provider).requireValue.page.items.single.isRead, false);
          await controller.loadMore();
          expect(repo.pageCalls, 1);
          repo.failRead = false;
          expect(await controller.markOpenedPageRead(), true);
          expect(repo.pageReads, hasLength(2));
          expect(c.read(provider).requireValue.pageReadFailed, false);
        },
      );

      test(
        'duplicate acknowledgements serialize and do not double-count a concurrent push',
        () async {
          final pending = Completer<NotificationReadReceipt>();
          final repo = FakeNotificationsRepository()
            ..onPageRead = (_) => pending.future;
          final c = await setup(repo, session: session);
          final controller = c.read(notificationInboxProvider(false).notifier);
          final read = controller.markOpenedPageRead();
          expect(await controller.markOpenedPageRead(), false);
          c
              .read(notificationCountProvider.notifier)
              .received(notification(3).id);
          pending.complete(
            NotificationReadReceipt(
              ids: repo.items.map((n) => n.id).toSet(),
              unreadCount: 1,
            ),
          );
          expect(await read, true);
          expect(c.read(notificationCountProvider).requireValue, 1);
          expect(repo.pageReads, hasLength(1));
        },
      );

      test(
        'same-user session replacement discards late acknowledgements',
        () async {
          final pending = Completer<NotificationReadReceipt>();
          final repo = FakeNotificationsRepository()
            ..onPageRead = (_) => pending.future;
          final c = await setup(repo, session: session);
          final oldIds = repo.items.map((n) => n.id).toSet();
          final read = c
              .read(notificationInboxProvider(false).notifier)
              .markOpenedPageRead();
          repo.items = [];
          c.updateOverrides([
            notificationSessionProvider.overrideWithValue(
              AuthenticatedSession(session.user),
            ),
            notificationsRepositoryProvider.overrideWithValue(repo),
          ]);
          await c.read(notificationInboxProvider(false).future);
          pending.complete(
            NotificationReadReceipt(ids: oldIds, unreadCount: 99),
          );
          expect(await read, false);
          expect(
            c.read(notificationInboxProvider(false)).requireValue.page.items,
            isEmpty,
          );
          expect(c.read(notificationCountProvider).requireValue, 0);
        },
      );

      test('empty and already-read pages send no acknowledgement', () async {
        for (final rows in [
          <AppNotification>[],
          [notification(1, read: true)],
        ]) {
          final repo = FakeNotificationsRepository()..items = rows;
          final c = await setup(repo, session: session);
          expect(
            await c
                .read(notificationInboxProvider(false).notifier)
                .markOpenedPageRead(),
            true,
          );
          expect(repo.pageReads, isEmpty);
        }
      });
    });
  }

  test(
    'page transport sends only bounded IDs and validates an exact receipt',
    () async {
      final calls = <RequestOptions>[];
      final ids = {notification(1).id, notification(2).id};
      Object? data = {'ids': ids.toList(), 'unread_count': 7};
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      final api = ApiClient(
        dio: dio,
        accessTokenResolver: () => 'test',
        localeResolver: () => 'ar',
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            calls.add(request);
            handler.resolve(
              Response(
                requestOptions: request,
                statusCode: 200,
                data: {'success': true, 'data': data},
              ),
            );
          },
        ),
      );
      final repo = NotificationsRepositoryImpl(
        NotificationsRemoteDataSource(api),
      );
      expect((await repo.markPageRead(ids)).unreadCount, 7);
      expect(calls.single.path, 'notifications/read-page');
      expect(calls.single.method, 'PATCH');
      expect(calls.single.data, {'ids': ids.toList()});
      expect(calls.single.headers['Authorization'], 'Bearer test');
      for (final malformed in [
        null,
        {
          'ids': [ids.first],
          'unread_count': 0,
        },
        {
          'ids': [ids.first, ids.first],
          'unread_count': 0,
        },
        {'ids': ids.toList(), 'unread_count': -1},
      ]) {
        data = malformed;
        await expectLater(repo.markPageRead(ids), throwsA(anything));
      }
      final count = calls.length;
      await expectLater(repo.markPageRead({}), throwsA(anything));
      await expectLater(repo.markPageRead({'../read-all'}), throwsA(anything));
      await expectLater(
        repo.markPageRead(List.generate(21, (i) => notification(i).id).toSet()),
        throwsA(anything),
      );
      expect(calls.length, count);
    },
  );

  test('provider push targets map to typed authorized destinations only', () {
    const roles = AppUserRole.provider;
    final cases = <Map<String, String>, String>{
      {'type': 'offer_accepted', 'order_id': '17', 'offer_id': '42'}:
          const ProviderOfferRoute(offerId: 42).location,
      {'type': 'order_paid', 'order_id': '17'}: const ProviderPaidOrderRoute(
        orderId: 17,
      ).location,
      {'type': 'order_completed', 'order_id': '17'}:
          const ProviderPaidOrderRoute(orderId: 17).location,
      {'type': 'new_order', 'order_id': '17', 'order_type': 'specific'}:
          const ProviderDirectOrderRoute(orderId: 17).location,
      {'type': 'new_order', 'order_id': '17', 'order_type': 'general'}:
          const ProviderGeneralRequestRoute(orderId: 17).location,
      {'type': 'new_message', 'conversation_id': '7'}:
          const ProviderConversationRoute(conversationId: 7).location,
      {'type': 'store_approved', 'request_id': '11'}:
          const ProviderStoreApplicationRoute(requestId: 11).location,
      {'type': 'store_rejected', 'request_id': '11'}:
          const ProviderStoreApplicationRoute(requestId: 11).location,
    };
    for (final entry in cases.entries) {
      final push = parsePushNotification({
        'notification_id': notification(1).id,
        'recipient_id': '44',
        ...entry.key,
      });
      expect(push, isNotNull);
      expect(notificationDestination(push!.item, roles), entry.value);
    }
    expect(
      notificationDestination(notification(1), roles),
      isNull,
    ); // Customer-only offer alert.
    expect(
      notificationDestination(
        notification(1, kind: NotificationKind.offerAccepted),
        AppUserRole.customer,
      ),
      isNull,
    );
    expect(
      parsePushNotification({
        'notification_id': notification(1).id,
        'recipient_id': '44',
        'type': 'store_approved',
        'request_id': '../users',
      }),
      isNull,
    );
  });
}
