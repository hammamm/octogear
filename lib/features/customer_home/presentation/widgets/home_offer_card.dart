import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../../customer_orders/presentation/widgets/order_widgets.dart';
import 'home_offer_summary.dart';

class HomeOfferCard extends StatelessWidget {
  const HomeOfferCard({required this.item, required this.onTap, super.key});
  final HomeOffer item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return OctoGearSurfaceCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.awaitingPayment) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: OctoGearColors.yellowSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                context.tr('home.accepted_awaiting_payment'),
                style: text.labelMedium?.copyWith(color: OctoGearColors.navy),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.storefront_outlined,
                size: 20,
                color: OctoGearColors.navy,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.offer.store?.name ??
                      context.tr('orders.store_unavailable'),
                  style: text.labelLarge?.copyWith(fontSize: 14, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            orderTitle(context, item.order),
            style: text.titleSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            context.tr(
              'orders.reference',
              args: [orderNumber(context, item.order.id)],
            ),
            style: text.bodySmall,
          ),
          const SizedBox(height: 16),
          Text(context.tr('home.offer_total_label'), style: text.bodySmall),
          Text(
            orderMoney(context, item.offer.totalPrice),
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr(
                    item.awaitingPayment
                        ? 'home.view_payment_details'
                        : 'offer_flow.view_offer',
                  ),
                  style: text.labelMedium,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}
