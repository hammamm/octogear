import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../controllers/notification_providers.dart';

/// One inexpensive count refresh for the foreground customer shell. Network
/// failures stop polling until an explicit refresh or an app-resume event.
class NotificationRefreshScope extends ConsumerStatefulWidget {
  const NotificationRefreshScope({required this.child, super.key});
  final Widget child;
  @override
  ConsumerState<NotificationRefreshScope> createState() =>
      _NotificationRefreshScopeState();
}

class _NotificationRefreshScopeState
    extends ConsumerState<NotificationRefreshScope>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _resumed = true;
  @override
  void initState() {
    super.initState();
    _resumed =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  void _refresh({bool resumed = false}) {
    if (!mounted ||
        !_resumed ||
        ref.read(notificationCustomerIdProvider) == null) {
      return;
    }
    final count = ref.read(notificationCountProvider);
    if (!count.isLoading && (resumed || !count.hasError)) {
      ref.invalidate(notificationCountProvider);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    if (_resumed) _refresh(resumed: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(notificationCountProvider);
    return widget.child;
  }
}

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(notificationCountProvider).value ?? 0;
    return IconButton(
      key: const Key('customer-notification-bell'),
      tooltip: count > 0
          ? context.tr(
              'notifications.unread_label',
              args: [
                NumberFormat.decimalPattern(
                  context.locale.languageCode,
                ).format(count),
              ],
            )
          : context.tr('notifications.title'),
      onPressed: () => const CustomerNotificationsRoute().push<void>(context),
      icon: NotificationBadge(count: count),
    );
  }
}

class NotificationBadge extends StatelessWidget {
  const NotificationBadge({required this.count, super.key});
  final int count;
  @override
  Widget build(BuildContext context) => Badge(
    isLabelVisible: count > 0,
    label: Text(
      count > 99
          ? '99+'
          : NumberFormat.decimalPattern(
              context.locale.languageCode,
            ).format(count),
    ),
    backgroundColor: OctoGearColors.navy,
    textColor: OctoGearColors.surface,
    child: const Icon(Icons.notifications_outlined),
  );
}

class NotificationsMenuEntry extends ConsumerWidget {
  const NotificationsMenuEntry({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(notificationCountProvider).value ?? 0;
    return OctoGearSurfaceCard(
      onTap: () => const CustomerNotificationsRoute().push<void>(context),
      child: Row(
        children: [
          NotificationBadge(count: count),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('notifications.title'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('notifications.menu_hint'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
