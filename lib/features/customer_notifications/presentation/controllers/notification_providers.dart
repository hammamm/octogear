import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:octogear/features/customer_notifications/domain/repositories/customer_notifications_repository.dart';

import '../../../../core/api/api_providers.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../../data/data_sources/notifications_remote_data_source.dart';
import '../../data/repositories/customer_notifications_repository_impl.dart';
import '../../domain/entities/customer_notification.dart';
import '../../domain/use_cases/get_notifications_use_case.dart';
import '../../domain/use_cases/get_unread_notification_count_use_case.dart';
import '../../domain/use_cases/mark_all_notifications_read_use_case.dart';
import '../../domain/use_cases/mark_notification_read_use_case.dart';

final notificationsRemoteDataSourceProvider = Provider(
  (ref) => NotificationsRemoteDataSource(ref.watch(apiClientProvider)),
);

final customerNotificationsRepositoryProvider =
    Provider<CustomerNotificationsRepository>(
      (ref) => CustomerNotificationsRepositoryImpl(
        ref.watch(notificationsRemoteDataSourceProvider),
      ),
    );

final getNotificationsProvider = Provider(
  (ref) => GetNotificationsUseCase(
    ref.watch(customerNotificationsRepositoryProvider),
  ),
);

final getUnreadNotificationCountProvider = Provider(
  (ref) => GetUnreadNotificationCountUseCase(
    ref.watch(customerNotificationsRepositoryProvider),
  ),
);

final markNotificationReadProvider = Provider(
  (ref) => MarkNotificationReadUseCase(
    ref.watch(customerNotificationsRepositoryProvider),
  ),
);

final markAllNotificationsReadProvider = Provider(
  (ref) => MarkAllNotificationsReadUseCase(
    ref.watch(customerNotificationsRepositoryProvider),
  ),
);

final notificationCustomerIdProvider = Provider<int?>((ref) {
  final session = ref.watch(sessionControllerProvider).asData?.value;
  return session is AuthenticatedSession &&
          session.user.role == AppUserRole.customer
      ? session.user.id
      : null;
});

final notificationCountProvider = FutureProvider.autoDispose<int>((ref) {
  if (ref.watch(notificationCustomerIdProvider) == null) return 0;
  return ref.watch(getUnreadNotificationCountProvider).call();
}, retry: (_, _) => null);

class NotificationInboxState {
  const NotificationInboxState({
    required this.page,
    this.pagesLoaded = 1,
    this.refreshing = false,
    this.loadingMore = false,
    this.readingId,
    this.markingAll = false,
    this.error,
  });
  final NotificationPage page;
  final int pagesLoaded;
  final bool refreshing, loadingMore, markingAll;
  final String? readingId;
  final Object? error;
  bool get busy => refreshing || loadingMore || markingAll || readingId != null;
}

final notificationInboxProvider = AsyncNotifierProvider.autoDispose
    .family<NotificationInboxController, NotificationInboxState, bool>(
      NotificationInboxController.new,
      retry: (_, _) => null,
    );

class NotificationInboxController
    extends AsyncNotifier<NotificationInboxState> {
  NotificationInboxController(this.unreadOnly);
  final bool unreadOnly;
  int _generation = 0;

  @override
  Future<NotificationInboxState> build() async {
    ++_generation;
    ref.onDispose(() => ++_generation);
    if (ref.watch(notificationCustomerIdProvider) == null) {
      return const NotificationInboxState(
        page: NotificationPage(items: [], unreadCount: 0),
      );
    }
    return NotificationInboxState(
      page: await ref
          .watch(getNotificationsProvider)
          .call(unreadOnly: unreadOnly),
    );
  }

  bool _current(int generation) => ref.mounted && generation == _generation;

  Future<void> refresh() async {
    if (ref.read(notificationCustomerIdProvider) == null) return;
    final previous = state.asData?.value;
    if (state.isLoading || previous?.busy == true) return;
    final generation = ++_generation;
    if (previous == null) {
      state = const AsyncLoading();
    } else {
      state = AsyncData(
        NotificationInboxState(
          page: previous.page,
          pagesLoaded: previous.pagesLoaded,
          refreshing: true,
        ),
      );
    }
    try {
      final page = await ref
          .read(getNotificationsProvider)
          .call(unreadOnly: unreadOnly);
      if (!_current(generation)) return;
      state = AsyncData(NotificationInboxState(page: page));
      ref.invalidate(notificationCountProvider);
    } catch (error, trace) {
      if (!_current(generation)) return;
      state = previous == null
          ? AsyncError(error, trace)
          : AsyncData(
              NotificationInboxState(
                page: previous.page,
                pagesLoaded: previous.pagesLoaded,
                error: error,
              ),
            );
    }
  }

  Future<void> loadMore() async {
    if (ref.read(notificationCustomerIdProvider) == null) return;
    final current = state.asData?.value;
    final cursor = current?.page.nextCursor;
    if (current == null || current.busy || cursor == null) return;
    final generation = _generation;
    state = AsyncData(
      NotificationInboxState(
        page: current.page,
        pagesLoaded: current.pagesLoaded,
        loadingMore: true,
      ),
    );
    try {
      final next = await ref
          .read(getNotificationsProvider)
          .call(unreadOnly: unreadOnly, cursor: cursor);
      if (!_current(generation)) return;
      if (next.nextCursor == cursor) {
        throw const FormatException('Repeated notification cursor.');
      }
      state = AsyncData(
        NotificationInboxState(
          pagesLoaded: current.pagesLoaded + 1,
          page: NotificationPage(
            items: List.unmodifiable(
              {
                for (final n in current.page.items) n.id: n,
                for (final n in next.items) n.id: n,
              }.values,
            ),
            unreadCount: next.unreadCount,
            nextCursor: next.nextCursor,
          ),
        ),
      );
    } catch (error) {
      if (_current(generation)) {
        state = AsyncData(
          NotificationInboxState(
            page: current.page,
            pagesLoaded: current.pagesLoaded,
            error: error,
          ),
        );
      }
    }
  }

  Future<bool> markRead(CustomerNotification item) => _mark(item);
  Future<bool> markAllRead() => _mark(null);

  Future<bool> _mark(CustomerNotification? item) async {
    if (ref.read(notificationCustomerIdProvider) == null) return false;
    final current = state.asData?.value;
    if (current == null || current.busy) return false;
    if (item?.isRead == true) return true;
    final generation = _generation;
    final link = ref.keepAlive();
    state = AsyncData(
      NotificationInboxState(
        page: current.page,
        pagesLoaded: current.pagesLoaded,
        readingId: item?.id,
        markingAll: item == null,
      ),
    );
    try {
      if (item == null) {
        await ref.read(markAllNotificationsReadProvider)();
      } else {
        await ref.read(markNotificationReadProvider)(item.id);
      }
      if (!_current(generation)) return false;
      final items = [
        for (final n in current.page.items)
          if (item != null && n.id != item.id) n else if (!unreadOnly) n.read(),
      ];
      state = AsyncData(
        NotificationInboxState(
          pagesLoaded: current.pagesLoaded,
          page: NotificationPage(
            items: List.unmodifiable(items),
            nextCursor: item == null && unreadOnly
                ? null
                : current.page.nextCursor,
            unreadCount: item == null
                ? 0
                : (current.page.unreadCount - 1).clamp(0, 1 << 31),
          ),
        ),
      );
      ref.invalidate(notificationCountProvider);
      return true;
    } catch (error) {
      if (_current(generation)) {
        state = AsyncData(
          NotificationInboxState(
            page: current.page,
            pagesLoaded: current.pagesLoaded,
            error: error,
          ),
        );
        // Idempotent read actions may be retried explicitly; don't claim success
        // locally when the response is missing or malformed.
        ref.invalidate(notificationCountProvider);
      }
      return false;
    } finally {
      link.close();
    }
  }
}
