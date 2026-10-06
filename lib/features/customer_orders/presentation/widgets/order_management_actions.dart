import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/customer_order.dart';
import '../controllers/order_management_controller.dart';
import '../controllers/order_lifecycle_controller.dart';
import 'order_widgets.dart';

class OrderManagementActions extends ConsumerWidget {
  const OrderManagementActions({required this.order, super.key});
  final CustomerOrder order;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderManagementProvider(order.id));
    final controller = ref.read(orderManagementProvider(order.id).notifier);
    final lifecycle = ref.watch(orderLifecycleProvider(order.id));
    final enabled =
        !state.busy &&
        !state.needsRefresh &&
        !state.deleted &&
        !lifecycle.busy &&
        !lifecycle.needsRefresh;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            if (order.canEdit)
              OutlinedButton.icon(
                key: const Key('order-edit'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onPressed: enabled
                    ? () => EditCustomerOrderRoute(
                        orderId: order.id,
                      ).push<void>(context)
                    : null,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(context.tr('order_management.edit')),
              ),
            if (order.canDelete)
              TextButton.icon(
                key: const Key('order-delete'),
                style: TextButton.styleFrom(
                  foregroundColor: OctoGearColors.error,
                ),
                onPressed: enabled
                    ? () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: Text(
                              dialogContext.tr('order_management.delete_title'),
                            ),
                            content: Text(
                              dialogContext.tr(
                                'order_management.delete_hint',
                                args: [orderTitle(context, order)],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                child: Text(
                                  dialogContext.tr('order_management.keep'),
                                ),
                              ),
                              TextButton(
                                key: const Key('order-confirm-delete'),
                                style: TextButton.styleFrom(
                                  foregroundColor: OctoGearColors.error,
                                ),
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                child: Text(
                                  dialogContext.tr('order_management.delete'),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true || !context.mounted) return;
                        final success = await controller.submit(order);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.tr('order_management.deleted'),
                              ),
                            ),
                          );
                          const CustomerOrdersRoute().go(context);
                        }
                      }
                    : null,
                icon: state.busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline, size: 18),
                label: Text(context.tr('order_management.delete')),
              ),
          ],
        ),
        if (!order.canEdit && order.canDelete)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              context.tr('order_management.edit_locked'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        OrderManagementFeedback(
          state: state,
          onRefresh: () async {
            await controller.refresh();
            if (context.mounted &&
                ref.read(orderManagementProvider(order.id)).deleted) {
              const CustomerOrdersRoute().go(context);
            }
          },
        ),
      ],
    );
  }
}

class OrderManagementFeedback extends StatelessWidget {
  const OrderManagementFeedback({
    required this.state,
    required this.onRefresh,
    super.key,
  });
  final OrderManagementState state;
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) {
    if (state.error == null && !state.needsRefresh) {
      return const SizedBox.shrink();
    }
    final errors = state.error?.fieldErrors.values
        .expand((items) => items)
        .toSet()
        .join('\n');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OctoGearFeedbackBanner(
            tone: OctoGearFeedbackTone.error,
            message: state.needsRefresh
                ? context.tr('order_management.refresh_hint')
                : (errors?.isNotEmpty ?? false)
                ? errors!
                : state.error?.serverMessage ??
                      ordersErrorMessage(context, state.error!),
          ),
          if (state.needsRefresh)
            TextButton.icon(
              onPressed: state.busy ? null : onRefresh,
              icon: const Icon(Icons.refresh),
              label: Text(context.tr('order_management.refresh')),
            ),
        ],
      ),
    );
  }
}
