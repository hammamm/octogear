import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../notifications/presentation/widgets/notification_entry.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../../provider_orders/presentation/widgets/provider_managed_order_widgets.dart';
import '../../../provider_orders/presentation/widgets/provider_offer_widgets.dart';
import '../../domain/entities/provider_dashboard.dart';
import '../controllers/provider_dashboard_providers.dart';

String dashboardSectionKey(ProviderDashboardSection section) =>
    switch (section) {
      ProviderDashboardSection.pendingDirect => 'pending_direct',
      ProviderDashboardSection.awaitingPayment => 'awaiting_payment',
      ProviderDashboardSection.paid => 'paid',
      ProviderDashboardSection.recent => 'recent',
    };

class DashboardError extends StatelessWidget {
  const DashboardError({required this.error, required this.retry, super.key});
  final Object error;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    final key = error is ApiFailure
        ? switch ((error as ApiFailure).type) {
            ApiFailureType.noConnection => 'errors.no_connection',
            ApiFailureType.timeout => 'errors.timeout',
            ApiFailureType.unauthorized => 'provider_requests.unauthorized',
            ApiFailureType.forbidden ||
            ApiFailureType.notFound => 'provider_dashboard.unavailable',
            _ => 'provider_dashboard.load_failed',
          }
        : 'provider_dashboard.load_failed';
    return OctoGearSurfaceCard(
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 32),
          const SizedBox(height: 12),
          Text(context.tr(key), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.tr('common.retry')),
          ),
        ],
      ),
    );
  }
}

class DashboardOrderCard extends ConsumerWidget {
  const DashboardOrderCard({required this.order, super.key});
  final ProviderDashboardOrder order;

  Future<void> _details(BuildContext context, WidgetRef ref) async {
    if (order.status == 'paid' || order.status == 'completed') {
      await ProviderPaidOrderRoute(orderId: order.id).push<void>(context);
    } else if (order.type == 'specific') {
      await ProviderDirectOrderRoute(orderId: order.id).push<void>(context);
    } else {
      await ProviderGeneralRequestRoute(orderId: order.id).push<void>(context);
    }
    if (context.mounted) {
      ref.invalidate(providerDashboardProvider);
      ref.invalidate(providerDashboardActivityProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: OctoGearSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                context.tr(
                  'provider_requests.request_number',
                  args: ['${order.id}'],
                ),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              DashboardOrderStatus(status: order.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.partName ?? context.tr('provider_requests.unnamed'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Divider(height: 24),
          _DetailLine(icon: Icons.storefront_outlined, text: order.store.name),
          if (order.customerName != null) ...[
            const SizedBox(height: 8),
            _DetailLine(icon: Icons.person_outline, text: order.customerName!),
          ],
          if (order.totalAmount != null) ...[
            const SizedBox(height: 12),
            Text(
              context.tr(
                order.status == 'paid' || order.status == 'completed'
                    ? 'provider_dashboard.paid_amount'
                    : 'provider_dashboard.order_total',
                args: [offerMoney(context, order.totalAmount!)],
              ),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            context.tr(
              'provider_dashboard.order_date',
              args: [
                DateFormat.yMMMd(
                  context.locale.toLanguageTag(),
                ).format(order.createdAt.toLocal()),
              ],
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          if (order.canChat) ...[
            FilledButton.icon(
              key: ValueKey('dashboard-chat-${order.id}'),
              onPressed: () async {
                await ProviderOrderChatRoute(
                  orderId: order.id,
                ).push<void>(context);
                if (context.mounted) {
                  ref.invalidate(providerDashboardProvider);
                  ref.invalidate(providerDashboardActivityProvider);
                }
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: Text(context.tr('provider_dashboard.chat_customer')),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton(
            key: ValueKey('dashboard-details-${order.id}'),
            onPressed: () => _details(context, ref),
            child: Text(context.tr('provider_requests.view_details')),
          ),
        ],
      ),
    ),
  );
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: OctoGearColors.structuralGray),
      const SizedBox(width: 8),
      Expanded(child: Text(text)),
    ],
  );
}

class DashboardOrderStatus extends StatelessWidget {
  const DashboardOrderStatus({required this.status, super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      'paid' => (OctoGearColors.success, Icons.payments_outlined),
      'completed' => (OctoGearColors.success, Icons.task_alt_rounded),
      'awaiting_payment' => (
        OctoGearColors.information,
        Icons.schedule_rounded,
      ),
      'pending' => (OctoGearColors.warning, Icons.hourglass_top_rounded),
      'rejected' => (OctoGearColors.error, Icons.cancel_outlined),
      _ => (OctoGearColors.structuralGray, Icons.info_outline),
    };
    final ink = Color.alphaBlend(Colors.black.withValues(alpha: 0.4), color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: ink, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              managedOrderStatus(context, status),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: ink),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    required this.titleKey,
    this.showBack = false,
    this.showRefresh = false,
    this.showNotifications = false,
    this.onRefresh,
    super.key,
  });
  final String titleKey;
  final bool showBack, showRefresh, showNotifications;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final title = Semantics(
      header: true,
      child: Text(
        context.tr(titleKey),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
    final actions = [
      if (showNotifications) ...[
        const NotificationBell(provider: true),
        const SizedBox(width: OctoGearSpacing.xSmall),
      ],
      if (showRefresh) ...[
        IconButton(
          key: const Key('dashboard-refresh'),
          onPressed: onRefresh,
          tooltip: context.tr('provider_dashboard.refresh'),
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: OctoGearSpacing.xSmall),
      ],
      const AppLanguageToggleButton(compact: true),
    ];
    if (MediaQuery.textScalerOf(context).scale(1) >= 1.5) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: 8),
          Row(
            children: [
              if (showBack) const BackButton(),
              const Spacer(),
              ...actions,
            ],
          ),
        ],
      );
    }
    return Row(
      children: [
        if (showBack) const BackButton(),
        Expanded(child: title),
        ...actions,
      ],
    );
  }
}
