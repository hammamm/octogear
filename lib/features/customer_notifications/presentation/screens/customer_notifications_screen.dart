import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../../customer_orders/presentation/widgets/order_widgets.dart';
import '../../domain/entities/customer_notification.dart';
import '../controllers/notification_providers.dart';
import '../widgets/notification_tile.dart';

class CustomerNotificationsScreen extends ConsumerStatefulWidget {
  const CustomerNotificationsScreen({super.key});
  @override
  ConsumerState<CustomerNotificationsScreen> createState() =>
      _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState
    extends ConsumerState<CustomerNotificationsScreen> {
  bool _unreadOnly = false;
  bool _opening = false;

  Future<void> _open(CustomerNotification item) async {
    if (_opening) return;
    _opening = true;
    final customerId = ref.read(notificationCustomerIdProvider);
    try {
      final controller = ref.read(
        notificationInboxProvider(_unreadOnly).notifier,
      );
      final read = await controller.markRead(item);
      if (!mounted ||
          customerId == null ||
          ref.read(notificationCustomerIdProvider) != customerId) {
        return;
      }
      if (!read) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('notifications.read_error'))),
        );
      }
      if (!item.canOpen) return;
      switch (item.kind) {
        case CustomerNotificationKind.offer:
          await CustomerOfferDetailsRoute(
            orderId: item.orderId!,
            offerId: item.offerId!,
          ).push<void>(context);
        case CustomerNotificationKind.message:
          await CustomerConversationRoute(
            conversationId: item.conversationId!,
          ).push<void>(context);
        case CustomerNotificationKind.orderPaid:
        case CustomerNotificationKind.orderCompleted:
        case CustomerNotificationKind.order:
          await CustomerOrderDetailsRoute(
            orderId: item.orderId!,
          ).push<void>(context);
        case CustomerNotificationKind.unknown:
          break;
      }
      if (mounted) ref.invalidate(notificationCountProvider);
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = notificationInboxProvider(_unreadOnly);
    final inbox = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final current = inbox.asData?.value;
    final count = ref.watch(notificationCountProvider);
    ref.listen(notificationCountProvider, (previous, next) {
      final value = ref.read(provider).asData?.value;
      if (previous?.value != null &&
          next.asData != null &&
          previous?.value != next.value &&
          value != null &&
          value.pagesLoaded == 1 &&
          !value.busy &&
          (ModalRoute.of(context)?.isCurrent ?? false)) {
        controller.refresh();
      }
    });
    return RefreshIndicator(
      onRefresh: () async {
        await controller.refresh();
        if (mounted) ref.invalidate(notificationCountProvider);
      },
      child: ListView(
        key: PageStorageKey('notifications-$_unreadOnly'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 32),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const BackButtonIcon(),
                onPressed: () => context.canPop()
                    ? context.pop()
                    : const CustomerHomeRoute().go(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('notifications.title'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const AppLanguageToggleButton(compact: true),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final unread in [false, true])
                ChoiceChip(
                  label: Text(
                    context.tr(
                      unread ? 'notifications.unread' : 'notifications.all',
                    ),
                  ),
                  selected: _unreadOnly == unread,
                  onSelected: current?.busy == true
                      ? null
                      : (_) => setState(() => _unreadOnly = unread),
                ),
              if ((count.value ?? current?.page.unreadCount ?? 0) > 0)
                TextButton.icon(
                  key: const Key('notifications-read-all'),
                  onPressed: current == null || current.busy
                      ? null
                      : () => controller.markAllRead(),
                  icon: const Icon(Icons.done_all, size: 20),
                  label: Text(context.tr('notifications.mark_all')),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (count.value case final int value)
            Text(
              context.tr(
                'notifications.unread_label',
                args: [
                  NumberFormat.decimalPattern(
                    context.locale.languageCode,
                  ).format(value),
                ],
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 16),
          ...inbox.when(
            loading: () => [
              Center(
                child: CircularProgressIndicator(
                  semanticsLabel: context.tr('notifications.loading'),
                ),
              ),
            ],
            error: (error, _) => [
              OrdersFeedback(
                title: context.tr('notifications.load_error'),
                message: ordersErrorMessage(context, error),
                icon: Icons.notifications_off_outlined,
                action: context.tr('common.retry'),
                onAction: controller.refresh,
              ),
            ],
            data: (state) => [
              if (state.refreshing || state.markingAll)
                const LinearProgressIndicator(),
              if (state.error != null) ...[
                OctoGearFeedbackBanner(
                  message: context.tr('notifications.update_error'),
                  tone: OctoGearFeedbackTone.error,
                ),
                TextButton.icon(
                  key: const Key('notifications-refresh'),
                  onPressed: state.busy ? null : controller.refresh,
                  icon: const Icon(Icons.refresh),
                  label: Text(context.tr('notifications.refresh')),
                ),
              ],
              if (state.page.items.isEmpty && state.page.nextCursor == null)
                OrdersFeedback(
                  title: context.tr(
                    _unreadOnly
                        ? 'notifications.unread_empty'
                        : 'notifications.empty',
                  ),
                  message: context.tr(
                    _unreadOnly
                        ? 'notifications.unread_empty_hint'
                        : 'notifications.empty_hint',
                  ),
                  icon: _unreadOnly
                      ? Icons.done_all_rounded
                      : Icons.notifications_none_rounded,
                ),
              for (var i = 0; i < state.page.items.length; i++) ...[
                if (i == 0 ||
                    notificationDayLabel(
                          context,
                          state.page.items[i].createdAt,
                        ) !=
                        notificationDayLabel(
                          context,
                          state.page.items[i - 1].createdAt,
                        ))
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(4, 12, 4, 10),
                    child: Text(
                      notificationDayLabel(
                        context,
                        state.page.items[i].createdAt,
                      ),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                CustomerNotificationTile(
                  key: ValueKey('notification-${state.page.items[i].id}'),
                  item: state.page.items[i],
                  busy: state.readingId == state.page.items[i].id,
                  onTap: state.busy ? null : () => _open(state.page.items[i]),
                ),
              ],
              if (state.page.nextCursor != null)
                TextButton.icon(
                  key: const Key('notifications-more'),
                  onPressed: state.busy ? null : controller.loadMore,
                  icon: const Icon(Icons.expand_more),
                  label: Text(
                    context.tr(
                      state.loadingMore
                          ? 'notifications.loading'
                          : 'notifications.more',
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
