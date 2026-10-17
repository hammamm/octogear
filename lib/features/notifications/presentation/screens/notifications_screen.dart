import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../../customer_orders/presentation/widgets/order_widgets.dart';
import '../../domain/entities/app_notification.dart';
import '../controllers/notification_providers.dart';
import '../controllers/push_providers.dart';
import '../widgets/notification_tile.dart';
import '../notification_destination.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({this.provider = false, super.key});
  final bool provider;
  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with WidgetsBindingObserver {
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.of(context);
    if (_router != router) {
      _router?.routeInformationProvider.removeListener(_schedulePageRead);
      _router = router;
      router.routeInformationProvider.addListener(_schedulePageRead);
    }
    _schedulePageRead();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _schedulePageRead();
  }

  void _schedulePageRead() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          ModalRoute.of(context)?.isCurrent != true ||
          !TickerMode.valuesOf(context).enabled) {
        return;
      }
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;
      final provider = notificationInboxProvider(_unreadOnly);
      final current = ref.read(provider).asData?.value;
      if (current == null ||
          current.busy ||
          current.pageReadFailed ||
          current.pendingReadIds.isEmpty) {
        return;
      }
      ref.read(provider.notifier).markOpenedPageRead();
    });
  }

  @override
  void dispose() {
    _router?.routeInformationProvider.removeListener(_schedulePageRead);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool _unreadOnly = false;
  bool _opening = false;

  Future<void> _open(AppNotification item) async {
    if (_opening) return;
    _opening = true;
    final session = ref.read(notificationSessionProvider);
    try {
      final controller = ref.read(
        notificationInboxProvider(_unreadOnly).notifier,
      );
      final read = await controller.markOpenedPageRead();
      if (!mounted ||
          session == null ||
          !identical(ref.read(notificationSessionProvider), session)) {
        return;
      }
      if (!read) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('notifications.read_error'))),
        );
      }
      final location = notificationDestination(item, session.user.role);
      if (location == null) return;
      if (item.kind == NotificationKind.message) {
        context.go(location);
      } else {
        await context.push<void>(location);
      }
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = notificationInboxProvider(_unreadOnly);
    ref.listen(provider, (_, _) => _schedulePageRead());
    final inbox = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final current = inbox.asData?.value;
    final count = ref.watch(notificationCountProvider);
    return RefreshIndicator(
      onRefresh: () async {
        await controller.refresh();
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
                    : widget.provider
                    ? const ProviderHomeRoute().go(context)
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
          Text(
            context.tr('notifications.page_read_hint'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (ref.watch(pushRepositoryProvider) != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                icon: const Icon(Icons.notifications_active_outlined),
                label: Text(context.tr('notifications.push_settings')),
                onPressed: () async {
                  try {
                    await ref.read(pushRepositoryProvider)?.openSettings();
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.tr('notifications.settings_error'),
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
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
              if (state.refreshing || state.markingAll || state.markingPage)
                const LinearProgressIndicator(),
              if (state.error != null) ...[
                OctoGearFeedbackBanner(
                  message: context.tr(
                    state.pageReadFailed
                        ? 'notifications.page_read_error'
                        : 'notifications.update_error',
                  ),
                  tone: OctoGearFeedbackTone.error,
                ),
                TextButton.icon(
                  key: const Key('notifications-refresh'),
                  onPressed: state.busy
                      ? null
                      : state.pageReadFailed
                      ? controller.markOpenedPageRead
                      : controller.refresh,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    context.tr(
                      state.pageReadFailed
                          ? 'common.retry'
                          : 'notifications.refresh',
                    ),
                  ),
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
                        : widget.provider
                        ? 'notifications.provider_empty_hint'
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
                NotificationTile(
                  key: ValueKey('notification-${state.page.items[i].id}'),
                  item: state.page.items[i],
                  provider: widget.provider,
                  busy: state.readingId == state.page.items[i].id,
                  onTap: state.busy ? null : () => _open(state.page.items[i]),
                ),
              ],
              if (state.page.nextCursor != null && !state.pageReadFailed)
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
