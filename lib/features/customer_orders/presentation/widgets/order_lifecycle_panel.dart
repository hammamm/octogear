import 'package:octogear/features/customer_orders/domain/entities/order_lifecycle_action.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/customer_order.dart';
import '../controllers/order_lifecycle_controller.dart';
import '../controllers/order_management_controller.dart';
import 'order_widgets.dart';

class OrderLifecyclePanel extends ConsumerWidget {
  const OrderLifecyclePanel({required this.order, super.key});
  final CustomerOrder order;

  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref,
    OrderLifecycleAction action,
  ) async {
    final key = action.name;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('order_flow.${key}_title')),
        scrollable: true,
        content: Text(
          dialogContext.tr(
            'order_flow.${key}_confirmation',
            args: [orderNumber(dialogContext, order.id)],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.tr('order_flow.go_back')),
          ),
          FilledButton(
            key: Key('order-confirm-$key'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.tr('order_flow.$key')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref
        .read(orderLifecycleProvider(order.id).notifier)
        .submit(order, action);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderLifecycleProvider(order.id));
    final controller = ref.read(orderLifecycleProvider(order.id).notifier);
    final management = ref.watch(orderManagementProvider(order.id));
    final enabled =
        !management.busy &&
        !management.needsRefresh &&
        !management.deleted &&
        !state.busy &&
        !state.needsRefresh &&
        state.result == null;
    final text = Theme.of(context).textTheme;
    final status = order.status;
    final activePurchase = [
      CustomerOrderStatus.awaitingPayment,
      CustomerOrderStatus.paid,
      CustomerOrderStatus.completed,
    ].contains(status);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: OctoGearSurfaceCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.tr('order_flow.progress'), style: text.titleMedium),
            const SizedBox(height: 12),
            Text(context.tr('order_flow.hint_${status.name}')),
            if (activePurchase) ...[
              const SizedBox(height: 16),
              _Step(label: context.tr('order_flow.selected'), done: true),
              _Step(
                label: context.tr('order_flow.payment'),
                done: status != CustomerOrderStatus.awaitingPayment,
              ),
              _Step(
                label: context.tr('order_flow.collected'),
                done: status == CustomerOrderStatus.completed,
              ),
              const Divider(height: 28),
              _CollectionOptions(
                key: ValueKey('collection-options-${order.id}'),
                enabled: !state.busy && !management.busy,
                store: order.displayStore,
                checkout: status == CustomerOrderStatus.awaitingPayment
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Divider(height: 28),
                          Text(
                            context.tr('order_flow.total'),
                            style: text.bodySmall,
                          ),
                          Text(
                            order.offeredPrice == null
                                ? context.tr('orders.price_unavailable')
                                : orderMoney(
                                    context,
                                    order.isGeneral
                                        ? order.offeredPrice!
                                        : order.offeredPrice! *
                                              (order.quantity ?? 1),
                                  ),
                            style: text.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Text(context.tr('order_flow.checkout_unavailable')),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            key: const Key('order-pay'),
                            onPressed: null,
                            icon: const Icon(Icons.lock_outline),
                            label: Text(context.tr('order_flow.pay_online')),
                          ),
                        ],
                      )
                    : null,
              ),
            ],
            if (order.payment case final OrderPaymentSummary payment) ...[
              const Divider(height: 28),
              Text(
                context.tr('order_flow.payment_details'),
                style: text.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(context.tr('order_flow.payment_${payment.status}')),
              Text(orderMoney(context, payment.amount), style: text.titleLarge),
              Text(
                context.tr(
                  'order_flow.payment_reference',
                  args: [orderNumber(context, payment.id)],
                ),
              ),
              Text(
                context.tr(
                  'order_flow.method_${['cash', 'credit_card'].contains(payment.method) ? payment.method : 'unknown'}',
                ),
              ),
              Text(
                context.tr(
                  'order_flow.recorded',
                  args: [
                    DateFormat.yMMMd(
                      context.locale.toLanguageTag(),
                    ).add_jm().format(payment.createdAt.toLocal()),
                  ],
                ),
                style: text.bodySmall,
              ),
            ],
            if (order.acceptedOfferId != null &&
                status != CustomerOrderStatus.cancelled) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('order-store-chat'),
                onPressed: state.busy
                    ? null
                    : () => CustomerOfferChatRoute(
                        orderId: order.id,
                        offerId: order.acceptedOfferId!,
                      ).go(context),
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(context.tr('order_flow.message_store')),
              ),
            ],
            if (order.canConfirmReceived) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('order-received'),
                onPressed: enabled
                    ? () =>
                          _confirm(context, ref, OrderLifecycleAction.received)
                    : null,
                icon: const Icon(Icons.inventory_2_outlined),
                label: Text(context.tr('order_flow.received')),
              ),
            ],
            if (order.canCancel) ...[
              const SizedBox(height: 8),
              TextButton(
                key: const Key('order-cancel'),
                onPressed: enabled
                    ? () => _confirm(context, ref, OrderLifecycleAction.cancel)
                    : null,
                style: TextButton.styleFrom(
                  foregroundColor: OctoGearColors.error,
                ),
                child: Text(context.tr('order_flow.cancel')),
              ),
            ],
            if (state.busy)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
            if (state.error != null) ...[
              const SizedBox(height: 12),
              OctoGearFeedbackBanner(
                tone: OctoGearFeedbackTone.error,
                message: context.tr(
                  state.error!.statusCode == 409
                      ? 'order_flow.changed'
                      : 'order_flow.check_result',
                ),
              ),
              TextButton.icon(
                key: const Key('order-refresh-status'),
                onPressed: state.busy ? null : controller.refresh,
                icon: const Icon(Icons.refresh),
                label: Text(context.tr('offer_flow.refresh_status')),
              ),
            ],
            if (state.result != null) ...[
              const SizedBox(height: 12),
              OctoGearFeedbackBanner(
                tone: OctoGearFeedbackTone.success,
                message: context.tr('order_flow.success_${state.result!.name}'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.done});
  final String label;
  final bool done;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 22,
          color: done ? OctoGearColors.success : Colors.grey,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
      ],
    ),
  );
}

/// This is a local checkout preview, not an order/payment mutation. Delivery
/// never exposes checkout; the existing pickup payment behavior is preserved.
class _CollectionOptions extends StatefulWidget {
  const _CollectionOptions({
    required this.enabled,
    required this.store,
    this.checkout,
    super.key,
  });
  final bool enabled;
  final OrderStore? store;
  final Widget? checkout;

  @override
  State<_CollectionOptions> createState() => _CollectionOptionsState();
}

class _CollectionOptionsState extends State<_CollectionOptions> {
  bool _pickup = true;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.tr('order_flow.fulfillment'), style: text.titleSmall),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final options = [
              _CollectionChoice(
                key: const Key('order-pickup-option'),
                icon: Icons.storefront_outlined,
                title: context.tr('order_flow.pickup'),
                subtitle: context.tr('order_flow.pickup_option_hint'),
                selected: _pickup,
                onTap: widget.enabled
                    ? () => setState(() => _pickup = true)
                    : null,
              ),
              _CollectionChoice(
                key: const Key('order-delivery-option'),
                icon: Icons.local_shipping_outlined,
                title: context.tr('order_flow.delivery'),
                subtitle: context.tr('order_flow.coming_soon'),
                selected: !_pickup,
                onTap: widget.enabled
                    ? () => setState(() => _pickup = false)
                    : null,
              ),
            ];
            if (constraints.maxWidth < 280 ||
                MediaQuery.textScalerOf(context).scale(14) > 20) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [options[0], const SizedBox(height: 10), options[1]],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: options[0]),
                  const SizedBox(width: 12),
                  Expanded(child: options[1]),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        if (_pickup) ...[
          Container(
            key: const Key('order-pickup-details'),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: OctoGearColors.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: OctoGearColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr('order_flow.pickup_store'),
                  style: text.labelMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      backgroundColor: OctoGearColors.surface,
                      foregroundColor: OctoGearColors.navy,
                      child: Icon(Icons.storefront_outlined),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.store?.name ??
                                context.tr('orders.store_unavailable'),
                            style: text.titleMedium,
                          ),
                          if (widget.store?.employeeName
                              case final String employee) ...[
                            const SizedBox(height: 4),
                            Text(employee, style: text.bodyMedium),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr('order_flow.pickup_hint'),
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          if (widget.checkout != null) widget.checkout!,
        ] else
          Semantics(
            liveRegion: true,
            child: OctoGearFeedbackBanner(
              key: const Key('order-delivery-coming-soon'),
              tone: OctoGearFeedbackTone.information,
              message: context.tr('order_flow.delivery_unavailable'),
            ),
          ),
      ],
    );
  }
}

class _CollectionChoice extends StatelessWidget {
  const _CollectionChoice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final IconData icon;
  final String title, subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    enabled: onTap != null,
    child: Material(
      color: selected ? OctoGearColors.yellowSoft : OctoGearColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? OctoGearColors.navy : OctoGearColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: OctoGearColors.navy, size: 26),
                  const Spacer(),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    color: selected
                        ? OctoGearColors.navy
                        : OctoGearColors.structuralGray,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    ),
  );
}
