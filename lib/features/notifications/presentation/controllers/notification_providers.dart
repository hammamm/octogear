import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:octogear/features/notifications/domain/repositories/notifications_repository.dart';

import '../../../../core/api/api_providers.dart';
import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../../data/data_sources/notifications_remote_data_source.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/use_cases/get_notifications_use_case.dart';
import '../../domain/use_cases/mark_notification_page_read_use_case.dart';
import '../../domain/use_cases/get_unread_notification_count_use_case.dart';
import '../../domain/use_cases/mark_all_notifications_read_use_case.dart';
import '../../domain/use_cases/mark_notification_read_use_case.dart';

final notificationsRemoteDataSourceProvider = Provider(
  (ref) => NotificationsRemoteDataSource(ref.watch(apiClientProvider)),
);

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepositoryImpl(
    ref.watch(notificationsRemoteDataSourceProvider),
  ),
);

final getNotificationsProvider = Provider(
  (ref) => GetNotificationsUseCase(ref.watch(notificationsRepositoryProvider)),
);

final getUnreadNotificationCountProvider = Provider(
  (ref) => GetUnreadNotificationCountUseCase(
    ref.watch(notificationsRepositoryProvider),
  ),
);

final markNotificationReadProvider = Provider(
  (ref) =>
      MarkNotificationReadUseCase(ref.watch(notificationsRepositoryProvider)),
);

final markAllNotificationsReadProvider = Provider(
  (ref) => MarkAllNotificationsReadUseCase(
    ref.watch(notificationsRepositoryProvider),
  ),
);

final notificationSessionProvider = Provider<AuthenticatedSession?>((ref) {
  final session = ref.watch(sessionControllerProvider).asData?.value;
  return session is AuthenticatedSession ? session : null;
});

final markNotificationPageReadProvider = Provider(
  (ref) => MarkNotificationPageReadUseCase(
    ref.watch(notificationsRepositoryProvider),
  ),
);

// Local badge only. Watching this provider must never issue an HTTP request.
final notificationCountProvider =
    AsyncNotifierProvider<NotificationCountController, int>(
      NotificationCountController.new,
    );

class NotificationCountController extends AsyncNotifier<int> {
  final Set<String> _seen = {};
  final Set<String> _read = {};
  @override
  int build() {
    ref.watch(notificationSessionProvider);
    _seen.clear();
    _read.clear();
    return 0;
  }

  void acknowledge(NotificationReadReceipt receipt) {
    // A push can arrive after the server calculated its receipt count. Preserve
    // known arrivals without counting them twice when the receipt includes them.
    final remaining = (state.value ?? 0) - receipt.ids.difference(_read).length;
    _seen.addAll(receipt.ids);
    _read.addAll(receipt.ids);
    state = AsyncData(
      remaining > receipt.unreadCount ? remaining : receipt.unreadCount,
    );
  }

  void reconcile(NotificationPage page) {
    _seen.addAll(page.items.map((item) => item.id));
    _read.addAll(
      page.items.where((item) => item.isRead).map((item) => item.id),
    );
    state = AsyncData(page.unreadCount);
  }

  void received(String id) {
    if (!_seen.add(id)) return;
    if (_seen.length > 1000) _seen.remove(_seen.first);
    state = AsyncData((state.value ?? 0) + 1);
  }

  void read({required bool all, String? id}) {
    if (id != null && !_read.add(id)) return;
    if (all) _read.addAll(_seen);
    state = AsyncData(all ? 0 : ((state.value ?? 0) - 1).clamp(0, 1 << 31));
  }
}

class NotificationInboxState {
  const NotificationInboxState({
    required this.page,
    this.pagesLoaded = 1,
    this.refreshing = false,
    this.loadingMore = false,
    this.readingId,
    this.markingAll = false,
    this.error,
    this.pendingReadIds = const {},
    this.markingPage = false,
    this.pageReadFailed = false,
  });
  final NotificationPage page;
  final int pagesLoaded;
  final bool refreshing, loadingMore, markingAll;
  final String? readingId;
  final Object? error;
  final Set<String> pendingReadIds;
  final bool markingPage, pageReadFailed;
  bool get busy =>
      refreshing ||
      loadingMore ||
      markingAll ||
      markingPage ||
      readingId != null;
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
  AuthenticatedSession? _session;

  @override
  Future<NotificationInboxState> build() async {
    ++_generation;
    ref.onDispose(() => ++_generation);
    _session = ref.watch(notificationSessionProvider);
    if (_session == null) {
      return const NotificationInboxState(
        page: NotificationPage(items: [], unreadCount: 0),
      );
    }
    final generation = _generation;
    final page = await ref
        .watch(getNotificationsProvider)
        .call(unreadOnly: unreadOnly);
    if (_current(generation)) {
      ref.read(notificationCountProvider.notifier).reconcile(page);
    }
    return NotificationInboxState(page: page, pendingReadIds: _pageIds(page));
  }

  Set<String> _pageIds(NotificationPage page) => Set.unmodifiable(
    page.items.where((item) => !item.isRead).map((item) => item.id),
  );

  bool _current(int generation) =>
      ref.mounted &&
      generation == _generation &&
      identical(_session, ref.read(notificationSessionProvider));

  Future<void> refresh() async {
    if (ref.read(notificationSessionProvider) == null) return;
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
      state = AsyncData(
        NotificationInboxState(page: page, pendingReadIds: _pageIds(page)),
      );
      ref.read(notificationCountProvider.notifier).reconcile(page);
    } catch (error, trace) {
      if (!_current(generation)) return;
      state = previous == null
          ? AsyncError(error, trace)
          : AsyncData(
              NotificationInboxState(
                page: previous.page,
                pagesLoaded: previous.pagesLoaded,
                pendingReadIds: previous.pendingReadIds,
                pageReadFailed: previous.pageReadFailed,
                error: error,
              ),
            );
    }
  }

  Future<void> loadMore() async {
    if (ref.read(notificationSessionProvider) == null) return;
    final current = state.asData?.value;
    final cursor = current?.page.nextCursor;
    if (current == null ||
        current.busy ||
        current.pendingReadIds.isNotEmpty ||
        cursor == null) {
      return;
    }
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
          pendingReadIds: _pageIds(next),
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

  Future<bool> markOpenedPageRead() async {
    final current = state.asData?.value;
    if (_session == null || current == null || current.busy) return false;
    if (current.pendingReadIds.isEmpty) return true;
    final generation = _generation;
    final link = ref.keepAlive();
    state = AsyncData(
      NotificationInboxState(
        page: current.page,
        pagesLoaded: current.pagesLoaded,
        pendingReadIds: current.pendingReadIds,
        markingPage: true,
      ),
    );
    try {
      final receipt = await ref.read(markNotificationPageReadProvider)(
        current.pendingReadIds,
      );
      if (!_current(generation)) return false;
      state = AsyncData(
        NotificationInboxState(
          pagesLoaded: current.pagesLoaded,
          page: NotificationPage(
            items: List.unmodifiable(
              current.page.items.map(
                (item) => receipt.ids.contains(item.id) ? item.read() : item,
              ),
            ),
            unreadCount: receipt.unreadCount,
            nextCursor: current.page.nextCursor,
          ),
        ),
      );
      ref.read(notificationCountProvider.notifier).acknowledge(receipt);
      return true;
    } catch (error) {
      if (_current(generation)) {
        state = AsyncData(
          NotificationInboxState(
            page: current.page,
            pagesLoaded: current.pagesLoaded,
            pendingReadIds: current.pendingReadIds,
            pageReadFailed: true,
            error: error,
          ),
        );
      }
      return false;
    } finally {
      link.close();
    }
  }

  Future<bool> markRead(AppNotification item) => _mark(item);
  Future<bool> markAllRead() => _mark(null);

  Future<bool> _mark(AppNotification? item) async {
    if (ref.read(notificationSessionProvider) == null) return false;
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
      ref
          .read(notificationCountProvider.notifier)
          .read(all: item == null, id: item?.id);
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
      }
      return false;
    } finally {
      link.close();
    }
  }
}
