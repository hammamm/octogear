import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/octogear_menu_entry.dart';
import '../controllers/notification_providers.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({this.provider = false, super.key});
  final bool provider;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(notificationCountProvider).value ?? 0;
    return IconButton(
      key: Key(
        provider ? 'provider-notification-bell' : 'customer-notification-bell',
      ),
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
      onPressed: () => provider
          ? const ProviderNotificationsRoute().push<void>(context)
          : const CustomerNotificationsRoute().push<void>(context),
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
  const NotificationsMenuEntry({this.provider = false, super.key});
  final bool provider;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(notificationCountProvider).value ?? 0;
    return OctoGearMenuEntry(
      leading: NotificationBadge(count: count),
      title: context.tr('notifications.title'),
      subtitle: context.tr('notifications.menu_hint'),
      onTap: () => provider
          ? const ProviderNotificationsRoute().push<void>(context)
          : const CustomerNotificationsRoute().push<void>(context),
    );
  }
}
