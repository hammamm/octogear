import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/customer_notification.dart';

class CustomerNotificationTile extends StatelessWidget {
  const CustomerNotificationTile({
    required this.item,
    required this.onTap,
    this.busy = false,
    super.key,
  });
  final CustomerNotification item;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final icon = switch (item.kind) {
      CustomerNotificationKind.offer => Icons.local_offer_outlined,
      CustomerNotificationKind.message => Icons.chat_bubble_outline_rounded,
      CustomerNotificationKind.orderPaid => Icons.payments_outlined,
      CustomerNotificationKind.orderCompleted => Icons.task_alt_rounded,
      _ => Icons.notifications_outlined,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OctoGearSurfaceCard(
        padding: const EdgeInsets.all(16),
        semanticLabel: context.tr(
          item.isRead ? 'notifications.read' : 'notifications.unread',
        ),
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: item.isRead
                  ? OctoGearColors.surfaceMuted
                  : OctoGearColors.yellowSoft,
              foregroundColor: OctoGearColors.navy,
              child: Icon(icon, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          context.tr('notifications.title_${item.kind.name}'),
                          style: text.titleSmall?.copyWith(
                            fontWeight: item.isRead
                                ? FontWeight.w500
                                : FontWeight.w800,
                          ),
                        ),
                      ),
                      if (!item.isRead) ...[
                        const SizedBox(width: 8),
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Icon(
                            Icons.circle,
                            size: 8,
                            color: OctoGearColors.navy,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr(
                      'notifications.body_${item.canOpen ? item.kind.name : 'unknown'}',
                      args: [
                        if (item.canOpen && item.orderId != null)
                          NumberFormat.decimalPattern(
                            context.locale.languageCode,
                          ).format(item.orderId),
                      ],
                    ),
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    DateFormat.yMMMd(
                      context.locale.languageCode,
                    ).add_jm().format(item.createdAt.toLocal()),
                    style: text.bodySmall,
                  ),
                  if (!item.canOpen) ...[
                    const SizedBox(height: 6),
                    Text(
                      context.tr('notifications.no_link'),
                      style: text.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            if (busy) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  semanticsLabel: context.tr('notifications.updating'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String notificationDayLabel(
  BuildContext context,
  DateTime date, {
  DateTime? now,
}) {
  final local = date.toLocal();
  final today = (now ?? DateTime.now()).toLocal();
  final age = DateTime.utc(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime.utc(local.year, local.month, local.day)).inDays;
  if (age == 0) return context.tr('notifications.today');
  if (age == 1) return context.tr('notifications.yesterday');
  return DateFormat.yMMMd(context.locale.languageCode).format(local);
}
