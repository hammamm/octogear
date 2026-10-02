import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/customer_order.dart';

String orderMoney(BuildContext context, int minor) => NumberFormat.currency(
  locale: context.locale.toLanguageTag(),
  symbol: '${context.tr('storefront.car.sar')}\u00a0',
  decimalDigits: 2,
).format(minor / 100);
String orderNumber(BuildContext context, int number) =>
    NumberFormat.decimalPattern(context.locale.toLanguageTag()).format(number);
String orderTitle(BuildContext context, CustomerOrder order) =>
    order.partName ??
    context.tr(
      order.isGeneral ? 'orders.general_title' : 'orders.part_unavailable',
    );
String orderCar(CustomerOrder order) => [
  order.carName,
  order.manufacturingYear?.toString(),
].whereType<String>().join(' · ');
String orderPriceLabel(BuildContext context, CustomerOrder order) => context.tr(
  order.paidAmount != null
      ? 'orders.paid_amount'
      : order.isGeneral
      ? 'orders.selected_total'
      : order.requestedUnitPrice != null
      ? 'orders.order_total'
      : 'orders.listed_total',
);

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({required this.order, super.key});
  final CustomerOrder order;
  @override
  Widget build(BuildContext context) {
    final color = switch (order.status) {
      CustomerOrderStatus.completed ||
      CustomerOrderStatus.paid => OctoGearColors.success,
      CustomerOrderStatus.rejected => OctoGearColors.error,
      _ => OctoGearColors.navy,
    };
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        context.tr(
          order.status == CustomerOrderStatus.pending && order.isGeneral
              ? 'orders.awaiting_offers'
              : 'orders.status_${order.status.name}',
        ),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

class CustomerOrderCard extends StatelessWidget {
  const CustomerOrderCard({
    required this.order,
    required this.onTap,
    super.key,
  });
  final CustomerOrder order;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: OctoGearSurfaceCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 8,
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    context.tr('orders.reference', args: ['${order.id}']),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  OrderStatusBadge(order: order),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: OctoGearColors.yellowSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      order.isGeneral
                          ? Icons.campaign_outlined
                          : Icons.build_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('orders.type_${order.type.name}'),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          orderTitle(context, order),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (orderCar(order).isNotEmpty)
                          Text(
                            orderCar(order),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.storefront_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.displayStore?.name ??
                          context.tr(
                            order.isGeneral && !order.hasSelectedOffer
                                ? 'orders.no_selected_store'
                                : 'orders.store_unavailable',
                          ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              if (order.displayTotal != null) ...[
                Text(
                  orderPriceLabel(context, order),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  orderMoney(context, order.displayTotal!),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ] else
                Text(
                  context.tr(
                    order.isGeneral
                        ? 'orders.no_selected_price'
                        : 'orders.price_unavailable',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  if (!order.isGeneral)
                    Text(
                      context.tr(
                        'orders.quantity_value',
                        args: [orderNumber(context, order.quantity!)],
                      ),
                    ),
                  if (order.isGeneral)
                    Text(
                      context.tr(
                        'orders.offer_count',
                        args: [orderNumber(context, order.offersCount)],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat.yMMMd(
                        context.locale.toLanguageTag(),
                      ).format(order.createdAt.toLocal()),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      context.tr('orders.view_details'),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class OrdersFeedback extends StatelessWidget {
  const OrdersFeedback({
    required this.title,
    required this.message,
    required this.icon,
    this.action,
    this.onAction,
    super.key,
  });
  final String title, message;
  final IconData icon;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => OctoGearSurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(icon, size: 42, color: OctoGearColors.navy),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        if (onAction != null) ...[
          const SizedBox(height: 20),
          FilledButton(onPressed: onAction, child: Text(action!)),
        ],
      ],
    ),
  );
}

String ordersErrorMessage(BuildContext context, Object error) => context.tr(
  switch (error) {
    ApiFailure(type: ApiFailureType.notFound) => 'orders.not_found',
    ApiFailure(type: ApiFailureType.forbidden || ApiFailureType.unauthorized) =>
      'orders.no_access',
    ApiFailure(type: ApiFailureType.timeout) => 'errors.timeout',
    ApiFailure(type: ApiFailureType.noConnection) => 'errors.no_connection',
    ApiFailure(type: ApiFailureType.rateLimited) => 'errors.rate_limited',
    _ => 'orders.load_error',
  },
);
