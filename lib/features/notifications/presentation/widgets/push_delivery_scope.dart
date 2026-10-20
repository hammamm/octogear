import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_router.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/localization/app_locale_controller.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/routing/app_route_paths.dart';
import '../../../customer_chats/domain/entities/chat_update.dart';
import '../../../customer_chats/presentation/controllers/chat_activity_controller.dart';
import '../../../customer_chats/presentation/controllers/chat_realtime_providers.dart';
import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/push_notification.dart';
import '../controllers/notification_providers.dart';
import '../controllers/push_providers.dart';
import '../notification_destination.dart';
import '../../../authentication/domain/entities/app_user.dart';

/// Application lifetime listeners handle cold-start taps after session restore.
/// No message or lifecycle callback fetches notification lists/counts.
class PushDeliveryScope extends ConsumerStatefulWidget {
  const PushDeliveryScope({required this.child, super.key});
  final Widget child;
  @override
  ConsumerState<PushDeliveryScope> createState() => _PushDeliveryScopeState();
}

class _PushDeliveryScopeState extends ConsumerState<PushDeliveryScope>
    with WidgetsBindingObserver {
  StreamSubscription<PushNotification>? _received, _opened;
  late final GoRouter _router;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _messageBanner;
  bool get _chatsVisible {
    final path = _router.routerDelegate.currentConfiguration.uri.path;
    return path == AppRoutePath.customerChats ||
        path.startsWith('${AppRoutePath.customerChats}/') ||
        path == AppRoutePath.providerChats ||
        path.startsWith('${AppRoutePath.providerChats}/');
  }

  bool get _foreground =>
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = ref.read(appRouterProvider);
    _router.routerDelegate.addListener(_navigationChanged);
    final delivery = ref.read(pushDeliveryProvider);
    _received = delivery?.received.listen(_receive);
    _opened = delivery?.opened.listen(_open);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bind();
      _navigationChanged();
    });
  }

  void _navigationChanged() {
    if (!mounted || !_chatsVisible) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chatsVisible) return;
      ref.read(chatActivityProvider.notifier).viewed();
      _messageBanner?.close();
      _messageBanner = null;
    });
  }

  void _messageAlert(String key, VoidCallback open) {
    if (!_foreground) return;
    final show = ref
        .read(chatActivityProvider.notifier)
        .receive(key: key, chatsVisible: _chatsVisible);
    if (!show) return;
    _messageBanner?.close();
    _messageBanner = ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: _bannerContent(context.tr('notifications.push_message')),
        action: SnackBarAction(
          label: context.tr('notifications.open'),
          onPressed: open,
        ),
      ),
    );
  }

  Widget _bannerContent(String message) => Row(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/icons/app_icon.png',
          width: 32,
          height: 32,
          cacheWidth: (32 * MediaQuery.devicePixelRatioOf(context)).round(),
          excludeFromSemantics: true,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(message)),
    ],
  );

  void _receiveChat(ChatUpdate update) {
    if (!mounted ||
        ref.read(notificationSessionProvider) == null ||
        update.kind != ChatUpdateKind.message ||
        update.message == null ||
        update.message!.mine) {
      return;
    }
    final recipient = ref.read(notificationSessionProvider);
    _messageAlert('message:${update.message!.id}', () {
      if (!mounted ||
          !identical(ref.read(notificationSessionProvider), recipient)) {
        return;
      }
      _messageBanner?.close();
      _router.go(
        recipient?.user.role == AppUserRole.provider
            ? ProviderConversationRoute(
                conversationId: update.conversationId!,
              ).location
            : CustomerConversationRoute(
                conversationId: update.conversationId!,
              ).location,
      );
    });
  }

  void _bind() {
    if (!mounted) return;
    final delivery = ref.read(pushDeliveryProvider);
    if (delivery == null) return;
    if (ref.read(sessionControllerProvider).asData?.value is SignedOutSession) {
      delivery.discardInitial();
    }
    delivery.bind(
      userId: ref.read(notificationSessionProvider)?.user.id,
      sessionKey: ref.read(sessionStorageProvider).cachedAccessToken,
      locale: ref.read(appLocaleProvider).code,
    );
  }

  bool _belongs(PushNotification event) =>
      mounted &&
      ref.read(notificationSessionProvider)?.user.id == event.recipientId &&
      notificationDestination(
            event.item,
            ref.read(notificationSessionProvider)!.user.role,
          ) !=
          null;

  void _receive(PushNotification event) {
    if (!_belongs(event)) return;
    ref.read(notificationCountProvider.notifier).received(event.item.id);
    if (event.item.kind == NotificationKind.message) {
      _messageAlert(
        event.messageId == null
            ? 'notification:${event.item.id}'
            : 'message:${event.messageId}',
        () => _open(event),
      );
      return;
    }
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: _bannerContent(
          context.tr(
            event.item.kind == NotificationKind.offer
                ? 'notifications.push_offer'
                : 'notifications.push_${event.item.kind.name}',
          ),
        ),
        action: SnackBarAction(
          label: context.tr('notifications.open'),
          onPressed: () => _open(event),
        ),
      ),
    );
  }

  void _open(PushNotification event) {
    if (!_belongs(event)) return;
    // The destination APIs still enforce ownership and resource availability.
    final location = notificationDestination(
      event.item,
      ref.read(notificationSessionProvider)!.user.role,
    );
    if (location == null) return;
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    ref.read(appRouterProvider).go(location);
    unawaited(_markOpened(event));
  }

  Future<void> _markOpened(PushNotification event) async {
    final session = ref.read(notificationSessionProvider);
    try {
      await ref.read(markNotificationReadProvider)(event.item.id);
      if (_belongs(event) &&
          identical(session, ref.read(notificationSessionProvider))) {
        ref
            .read(notificationCountProvider.notifier)
            .read(all: false, id: event.item.id);
      }
    } catch (_) {
      /* Keep navigation usable; the inbox can retry marking read. */
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recheck OS permission/token only; never refresh the inbox on resume.
      unawaited(ref.read(pushDeliveryProvider)?.sync());
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionControllerProvider, (_, _) {
      _messageBanner?.close();
      _messageBanner = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _bind());
    });
    // Initialize the shared badge even when entering through a deep link.
    ref.listen(notificationCountProvider, (_, _) {});
    // Hold one connection across customer tabs; no notification inbox fetches.
    ref.listen(chatRealtimeUpdatesProvider, (_, next) {
      final update = next.asData?.value;
      if (update != null) _receiveChat(update);
    });
    ref.listen(appLocaleProvider, (_, _) => _bind());
    return widget.child;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.routerDelegate.removeListener(_navigationChanged);
    unawaited(_received?.cancel());
    unawaited(_opened?.cancel());
    super.dispose();
  }
}
