import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/notifications/domain/entities/app_notification.dart';
import 'package:octogear/features/notifications/presentation/controllers/notification_providers.dart';

import 'notification_fixtures.dart';

void main() {
  ProviderContainer setup(
    FakeNotificationsRepository repo, {
    AuthenticatedSession? session = notificationSession,
  }) {
    final container = ProviderContainer(
      overrides: [
        notificationSessionProvider.overrideWithValue(session),
        notificationsRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    container.listen(notificationCountProvider, (_, _) {});
    return container;
  }

  Future<void> flush(ProviderContainer container) async {
    await Future<void>.delayed(Duration.zero);
    await container.pump();
  }

  for (final session in [notificationSession, providerNotificationSession]) {
    test('${session.user.role} loads once without opening the inbox', () async {
      final repo = FakeNotificationsRepository()..onCount = () async => 12;
      final c = setup(repo, session: session);
      await flush(c);
      expect(c.read(notificationCountProvider).requireValue, 12);
      final subscription = c.listen(notificationCountProvider, (_, _) {});
      subscription.close();
      await flush(c);
      expect(repo.countCalls, 1);
      expect(repo.pageCalls, 0);
    });
  }

  test('signed-out state makes no request, login starts it', () async {
    final repo = FakeNotificationsRepository();
    final c = setup(repo, session: null);
    await flush(c);
    expect(repo.countCalls, 0);
    expect(c.read(notificationCountProvider).requireValue, 0);
    c.updateOverrides([
      notificationSessionProvider.overrideWithValue(notificationSession),
      notificationsRepositoryProvider.overrideWithValue(repo),
    ]);
    await flush(c);
    expect(repo.countCalls, 1);
    expect(c.read(notificationCountProvider).requireValue, 2);
  });

  for (final next in [
    null,
    AuthenticatedSession(notificationSession.user),
    providerNotificationSession,
  ]) {
    test('late response cannot update replacement session: $next', () async {
      final pending = Completer<int>();
      final repo = FakeNotificationsRepository()
        ..onCount = () => pending.future;
      final c = setup(repo);
      expect(repo.countCalls, 1);
      repo.onCount = () async => 4;
      c.updateOverrides([
        notificationSessionProvider.overrideWithValue(next),
        notificationsRepositoryProvider.overrideWithValue(repo),
      ]);
      await flush(c);
      pending.complete(90);
      await flush(c);
      expect(
        c.read(notificationCountProvider).requireValue,
        next == null ? 0 : 4,
      );
      expect(repo.countCalls, next == null ? 1 : 2);
    });
  }

  test('disposed provider ignores late completion', () async {
    final pending = Completer<int>();
    final repo = FakeNotificationsRepository()..onCount = () => pending.future;
    final c = ProviderContainer(
      overrides: [
        notificationSessionProvider.overrideWithValue(notificationSession),
        notificationsRepositoryProvider.overrideWithValue(repo),
      ],
    );
    c.read(notificationCountProvider);
    c.dispose();
    pending.complete(90);
    await Future<void>.delayed(Duration.zero);
  });

  for (final update in ['page', 'receipt', 'read', 'all']) {
    test('late initial response cannot overwrite $update', () async {
      final pending = Completer<int>();
      final repo = FakeNotificationsRepository()
        ..onCount = () => pending.future;
      final c = setup(repo);
      final controller = c.read(notificationCountProvider.notifier);
      controller.received(notification(1).id);
      switch (update) {
        case 'page':
          controller.reconcile(
            const NotificationPage(items: [], unreadCount: 3),
          );
        case 'receipt':
          controller.acknowledge(
            NotificationReadReceipt(ids: {notification(1).id}, unreadCount: 3),
          );
        default:
          controller.read(all: update == 'all', id: notification(1).id);
      }
      final expected = c.read(notificationCountProvider).requireValue;
      pending.complete(20);
      await flush(c);
      expect(c.read(notificationCountProvider).requireValue, expected);
    });
  }

  test(
    'overlapping push is not double counted in the server snapshot',
    () async {
      final pending = Completer<int>();
      final repo = FakeNotificationsRepository()
        ..onCount = () => pending.future;
      final c = setup(repo);
      final controller = c.read(notificationCountProvider.notifier);
      controller.received(notification(1).id);
      pending.complete(8);
      await flush(c);
      expect(c.read(notificationCountProvider).requireValue, 8);
      controller.received(notification(1).id);
      expect(c.read(notificationCountProvider).requireValue, 8);
      controller.received(notification(2).id);
      expect(c.read(notificationCountProvider).requireValue, 9);
    },
  );

  test('older zero snapshot cannot erase known arrivals', () async {
    final pending = Completer<int>();
    final repo = FakeNotificationsRepository()..onCount = () => pending.future;
    final c = setup(repo);
    c.read(notificationCountProvider.notifier).received(notification(1).id);
    pending.complete(0);
    await flush(c);
    expect(c.read(notificationCountProvider).requireValue, 1);
  });

  test(
    'failure does not retry automatically; inbox recovers the badge',
    () async {
      final repo = FakeNotificationsRepository()..failCount = true;
      final c = setup(repo);
      await flush(c);
      expect(c.read(notificationCountProvider).hasError, true);
      expect(repo.countCalls, 1);
      c.listen(notificationInboxProvider(false), (_, _) {});
      await c.read(notificationInboxProvider(false).future);
      expect(c.read(notificationCountProvider).requireValue, 2);
      expect(repo.countCalls, 1);
    },
  );

  test('startup failure preserves push updates', () async {
    final pending = Completer<int>();
    final repo = FakeNotificationsRepository()..onCount = () => pending.future;
    final c = setup(repo);
    c.read(notificationCountProvider.notifier).received(notification(1).id);
    pending.completeError(Exception('offline'));
    await flush(c);
    expect(c.read(notificationCountProvider).requireValue, 1);
  });
}
