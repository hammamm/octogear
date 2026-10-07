import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/octogear_theme.dart';
import '../../domain/entities/chat.dart';

String chatDayLabel(BuildContext context, DateTime date, {DateTime? now}) {
  final local = date.toLocal();
  final today = (now ?? DateTime.now()).toLocal();
  // UTC calendar arithmetic avoids 23/25-hour DST day boundaries.
  final days = DateTime.utc(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime.utc(local.year, local.month, local.day)).inDays;
  if (days == 0) return context.tr('chat.today');
  if (days == 1) return context.tr('chat.yesterday');
  final locale = context.locale.languageCode;
  if (days > 1 && days < 7) return DateFormat.EEEE(locale).format(local);
  return DateFormat.yMMMd(locale).format(local);
}

bool sameChatDay(DateTime a, DateTime b) {
  final x = a.toLocal(), y = b.toLocal();
  return x.year == y.year && x.month == y.month && x.day == y.day;
}

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({super.key, required this.message});
  final ChatMessage message;
  @override
  Widget build(BuildContext context) {
    final color = message.mine ? Colors.white : OctoGearColors.navy;
    return Align(
      alignment: message.mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        key: ValueKey('message-${message.id}'),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .82,
        ),
        margin: const EdgeInsetsDirectional.only(
          start: 12,
          end: 12,
          top: 3,
          bottom: 3,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: message.mine ? OctoGearColors.navy : Colors.white,
          border: message.mine
              ? null
              : Border.all(color: const Color(0xFFE1E4EA)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(
              message.text,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat.jm(
                    context.locale.languageCode,
                  ).format(message.createdAt.toLocal()),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color.withValues(alpha: .8),
                  ),
                ),
                if (message.mine) ...[
                  const SizedBox(width: 6),
                  Tooltip(
                    message: context.tr('chat.sent'),
                    child: Icon(Icons.check_rounded, size: 14, color: color),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
