import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/core/api/api_client.dart';
import 'package:octogear/core/api/api_failure.dart';
import 'package:octogear/features/customer_notifications/data/data_sources/notifications_remote_data_source.dart';
import 'package:octogear/features/customer_notifications/data/models/notification_dto.dart';
import 'package:octogear/features/customer_notifications/data/repositories/customer_notifications_repository_impl.dart';
import 'package:octogear/features/customer_notifications/domain/entities/customer_notification.dart';
import 'package:octogear/features/customer_notifications/presentation/controllers/notification_providers.dart';

import 'notification_fixtures.dart';

void main() {
  Future<ProviderContainer> setup(
    FakeNotificationsRepository repo, {
    bool unread = false,
  }) async {
    final c = ProviderContainer(
      overrides: [
        notificationCustomerIdProvider.overrideWithValue(1),
        customerNotificationsRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(c.dispose);
    c.listen(notificationInboxProvider(unread), (_, _) {});
    await c.read(notificationInboxProvider(unread).future);
    return c;
  }

  test(
    'opening does not write; read failures retain unread state and retry',
    () async {
      final repo = FakeNotificationsRepository();
      final c = await setup(repo);
      expect(repo.readCalls, 0);
      final controller = c.read(notificationInboxProvider(false).notifier);
      repo.failRead = true;
      expect(await controller.markRead(notification(1)), false);
      expect(
        c.read(notificationInboxProvider(false)).requireValue.page.unreadCount,
        2,
      );
      expect(
        c
            .read(notificationInboxProvider(false))
            .requireValue
            .page
            .items
            .first
            .isRead,
        false,
      );
      repo.failRead = false;
      expect(await controller.markRead(notification(1)), true);
      expect(
        c.read(notificationInboxProvider(false)).requireValue.page.unreadCount,
        1,
      );
    },
  );
  test('unread filter removes read rows; mark all clears it', () async {
    final repo = FakeNotificationsRepository();
    final c = await setup(repo, unread: true);
    final controller = c.read(notificationInboxProvider(true).notifier);
    await controller.markRead(notification(1));
    expect(
      c
          .read(notificationInboxProvider(true))
          .requireValue
          .page
          .items
          .map((n) => n.id),
      [notification(2).id],
    );
    await controller.markAllRead();
    expect(
      c.read(notificationInboxProvider(true)).requireValue.page.items,
      isEmpty,
    );
    expect(
      c.read(notificationInboxProvider(true)).requireValue.page.unreadCount,
      0,
    );
  });
  test('duplicate taps serialize read actions', () async {
    final pending = Completer<void>();
    final repo = FakeNotificationsRepository()..onRead = () => pending.future;
    final c = await setup(repo);
    final controller = c.read(notificationInboxProvider(false).notifier);
    final first = controller.markRead(notification(1));
    expect(await controller.markRead(notification(1)), false);
    expect(await controller.markAllRead(), false);
    pending.complete();
    expect(await first, true);
    expect(repo.readCalls, 1);
  });
  test(
    'older pages merge without duplicates; failure retains cursor and rows',
    () async {
      final repo = FakeNotificationsRepository()
        ..onPage = (_, _) async => NotificationPage(
          items: [notification(1)],
          unreadCount: 2,
          nextCursor: 'next',
        );
      final c = await setup(repo);
      final controller = c.read(notificationInboxProvider(false).notifier);
      repo.failPage = true;
      await controller.loadMore();
      expect(
        c.read(notificationInboxProvider(false)).requireValue.page.nextCursor,
        'next',
      );
      repo.failPage = false;
      repo.onPage = (_, cursor) async {
        expect(cursor, 'next');
        return NotificationPage(
          items: [notification(1), notification(2)],
          unreadCount: 2,
        );
      };
      await controller.loadMore();
      expect(
        c.read(notificationInboxProvider(false)).requireValue.page.items,
        hasLength(2),
      );
      expect(
        c.read(notificationInboxProvider(false)).requireValue.pagesLoaded,
        2,
      );
    },
  );
  test('logout discards late reads and prevents authenticated calls', () async {
    final pending = Completer<void>();
    final repo = FakeNotificationsRepository()..onRead = () => pending.future;
    final c = await setup(repo);
    final controller = c.read(notificationInboxProvider(false).notifier);
    final read = controller.markRead(notification(1));
    c.updateOverrides([
      notificationCustomerIdProvider.overrideWithValue(null),
      customerNotificationsRepositoryProvider.overrideWithValue(repo),
    ]);
    await c.read(notificationInboxProvider(false).future);
    pending.complete();
    expect(await read, false);
    expect(
      c.read(notificationInboxProvider(false)).requireValue.page.items,
      isEmpty,
    );
    await controller.refresh();
    await controller.loadMore();
    expect(await controller.markAllRead(), false);
    expect(await c.read(notificationCountProvider.future), 0);
    expect(repo.pageCalls, 1);
    expect(repo.countCalls, 0);
  });
  test('malformed targets and unknown payloads never open arbitrary links', () {
    Map<String, Object?> json(Object? payload) => {
      'id': notification(1).id,
      'is_read': false,
      'created_at': '2026-10-06T12:00:00Z',
      'payload': payload,
    };
    expect(
      notificationFromJson(
        json({'type': 'new_offer', 'order_id': -1, 'offer_id': '42'}),
      ).toEntity().canOpen,
      false,
    );
    expect(
      notificationFromJson(
        json({'type': 'future_type', 'url': 'https://evil.test'}),
      ).toEntity().canOpen,
      false,
    );
    expect(
      notificationFromJson(json(null)).kind,
      CustomerNotificationKind.unknown,
    );
    expect(
      () => notificationFromJson(json(null)..['created_at'] = 'invalid'),
      throwsFormatException,
    );
    expect(
      () => notificationFromJson(json(null)..['id'] = '../read-all'),
      throwsFormatException,
    );
  });
  test(
    'API contracts are authenticated, localized, and reject false read receipts',
    () async {
      final calls = <RequestOptions>[];
      Object? responseData = {
        'items': [],
        'unread_count': 3,
        'next_cursor': 'cursor',
      };
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      final api = ApiClient(
        dio: dio,
        accessTokenResolver: () => 'token',
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
                data: {'success': true, 'data': responseData},
              ),
            );
          },
        ),
      );
      final repo = CustomerNotificationsRepositoryImpl(
        NotificationsRemoteDataSource(api),
      );
      expect(
        (await repo.page(unreadOnly: true, cursor: 'older')).unreadCount,
        3,
      );
      expect(calls.single.queryParameters, {'unread': 1, 'cursor': 'older'});
      expect(calls.single.headers['Authorization'], 'Bearer token');
      expect(calls.single.headers['Accept-Language'], 'ar');
      responseData = {'unread_count': 3};
      expect(await repo.unreadCount(), 3);
      responseData = {'id': notification(1).id, 'is_read': false};
      await expectLater(
        repo.markRead(notification(1).id),
        throwsA(isA<ApiFailure>()),
      );
      responseData = {'id': notification(2).id, 'is_read': true};
      await expectLater(
        repo.markRead(notification(1).id),
        throwsA(isA<ApiFailure>()),
      );
      responseData = {'id': notification(1).id, 'is_read': true};
      await repo.markRead(notification(1).id);
      expect(calls.last.method, 'PATCH');
      final count = calls.length;
      await expectLater(
        repo.markRead('../read-all'),
        throwsA(isA<ApiFailure>()),
      );
      expect(calls.length, count);
      responseData = null;
      await expectLater(repo.markAllRead(), throwsA(isA<ApiFailure>()));
      responseData = 'All read';
      await repo.markAllRead();
    },
  );
}
