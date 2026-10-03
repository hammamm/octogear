import '../widgets/order_management_actions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../controllers/customer_orders_providers.dart';
import '../widgets/order_widgets.dart';
import '../widgets/general_order_details.dart';
import '../widgets/specific_order_details.dart';

class CustomerOrderDetailsScreen extends ConsumerWidget {
  const CustomerOrderDetailsScreen({required this.orderId, super.key});
  final int orderId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(customerOrderProvider(orderId));
    return RefreshIndicator(
      onRefresh: () async {
        try {
          ref.invalidate(customerOrderProvider(orderId));
          await ref.read(customerOrderProvider(orderId).future);
          ref.invalidate(customerOrdersProvider);
        } catch (_) {
          /* Visible provider error. */
        }
      },
      child: ListView(
        key: PageStorageKey('order-details-$orderId'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 32),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const BackButtonIcon(),
                onPressed: () => context.canPop()
                    ? context.pop()
                    : const CustomerOrdersRoute().go(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('orders.details_title'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const AppLanguageToggleButton(compact: true),
            ],
          ),
          const SizedBox(height: 20),
          ...order.when(
            skipLoadingOnRefresh: false,
            loading: () => [
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: context.tr('orders.loading'),
                  ),
                ),
              ),
            ],
            error: (error, _) => [
              OrdersFeedback(
                title: context.tr('orders.error_title'),
                message: ordersErrorMessage(context, error),
                icon: Icons.receipt_long_outlined,
                action: context.tr('common.retry'),
                onAction: () => ref.invalidate(customerOrderProvider(orderId)),
              ),
            ],
            data: (order) => [
              OrderManagementActions(order: order),
              if (order.canEdit || order.canDelete) const SizedBox(height: 12),
              if (order.isGeneral)
                GeneralOrderDetails(order: order)
              else
                SpecificOrderDetails(order: order),
            ],
          ),
        ],
      ),
    );
  }
}
