import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../../customer_orders/domain/entities/customer_order.dart';
import '../../../customer_orders/presentation/widgets/order_widgets.dart';

/// A short summary; prices, images and actions belong in request details.
class HomeRequestCard extends StatelessWidget {
  const HomeRequestCard({required this.order, required this.onTap, super.key});

  final CustomerOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final vehicle = [
      order.companyName,
      order.carName,
      order.manufacturingYear?.toString(),
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' · ');
    final waiting =
        order.isGeneral &&
        order.status == CustomerOrderStatus.pending &&
        order.offersCount == 0;
    final received =
        order.isGeneral &&
        order.status == CustomerOrderStatus.pending &&
        order.offersCount > 0;
    final status = context.tr(
      waiting
          ? 'orders.awaiting_offers'
          : received
          ? 'home.offers_received'
          : 'orders.status_${order.status.name}',
    );
    final color = switch (order.status) {
      CustomerOrderStatus.completed ||
      CustomerOrderStatus.paid => OctoGearColors.success,
      CustomerOrderStatus.rejected => OctoGearColors.error,
      _ => OctoGearColors.navy,
    };
    return OctoGearSurfaceCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(orderTitle(context, order), style: text.titleSmall),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: OctoGearColors.navy,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            vehicle.isEmpty
                ? context.tr(
                    'orders.reference',
                    args: [orderNumber(context, order.id)],
                  )
                : vehicle,
            style: text.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text(
                    status,
                    style: text.labelMedium?.copyWith(color: color),
                  ),
                ),
              ),
              if (order.isGeneral && order.offersCount > 0)
                Text(
                  context.tr(
                    'orders.offer_count',
                    args: [orderNumber(context, order.offersCount)],
                  ),
                  style: text.bodySmall,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
