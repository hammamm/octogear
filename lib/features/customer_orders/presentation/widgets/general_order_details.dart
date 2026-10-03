import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/customer_order.dart';
import 'order_photo.dart';
import 'order_widgets.dart';

class GeneralOrderDetails extends StatelessWidget {
  const GeneralOrderDetails({required this.order, super.key});
  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final selected = order.offers
        .where((offer) => offer.id == order.acceptedOfferId)
        .firstOrNull;
    final available = order.offers
        .where(
          (offer) =>
              offer.id != order.acceptedOfferId &&
              offer.status == CustomerOfferStatus.pending,
        )
        .toList();
    final history = order.offers
        .where(
          (offer) =>
              offer.id != order.acceptedOfferId &&
              offer.status != CustomerOfferStatus.pending,
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OctoGearSurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(orderTitle(context, order), style: text.titleLarge),
              if (orderCar(order).isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(orderCar(order), style: text.bodyMedium),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OrderStatusBadge(order: order),
                  Text(
                    context.tr(
                      'orders.reference',
                      args: [orderNumber(context, order.id)],
                    ),
                    style: text.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (order.hasSelectedOffer) ...[
          Text(
            context.tr('offer_flow.selected_offer'),
            style: text.titleMedium,
          ),
          const SizedBox(height: 8),
          if (selected != null)
            _OfferPreview(order: order, offer: selected, selected: true)
          else
            OctoGearSurfaceCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.acceptedStore?.name ??
                        context.tr('orders.store_unavailable'),
                  ),
                  if (order.displayTotal != null)
                    Text(
                      orderMoney(context, order.displayTotal!),
                      style: text.titleLarge,
                    ),
                ],
              ),
            ),
          if (order.status == CustomerOrderStatus.awaitingPayment)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                context.tr('offer_flow.awaiting_payment_hint'),
                style: text.bodySmall,
              ),
            ),
        ] else ...[
          Text(
            context.tr(
              'orders.offers_title',
              args: [orderNumber(context, available.length)],
            ),
            style: text.titleMedium,
          ),
          const SizedBox(height: 8),
          if (available.isEmpty)
            OctoGearSurfaceCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.hourglass_empty_rounded,
                    size: 22,
                    color: OctoGearColors.navy,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr(
                        order.status == CustomerOrderStatus.pending
                            ? 'offer_flow.waiting'
                            : 'offer_flow.no_available_offers',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          for (final offer in available)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _OfferPreview(order: order, offer: offer),
            ),
        ],
        if (history.isNotEmpty) ...[
          const SizedBox(height: 12),
          ExpansionTile(
            key: PageStorageKey('order-offer-history-${order.id}'),
            tilePadding: const EdgeInsets.symmetric(horizontal: 4),
            title: Text(
              context.tr(
                'offer_flow.previous_offers',
                args: [orderNumber(context, history.length)],
              ),
              style: text.titleSmall,
            ),
            children: [
              for (final offer in history)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _OfferPreview(order: order, offer: offer),
                ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        OctoGearSurfaceCard(
          padding: EdgeInsets.zero,
          child: ExpansionTile(
            key: PageStorageKey('request-information-${order.id}'),
            title: Text(
              context.tr('offer_flow.request_information'),
              style: text.titleSmall,
            ),
            leading: const Icon(Icons.description_outlined, size: 22),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Detail(
                label: context.tr('orders.created'),
                value: DateFormat.yMMMd(
                  context.locale.toLanguageTag(),
                ).format(order.createdAt.toLocal()),
              ),
              if (order.paidAmount != null)
                _Detail(
                  label: context.tr('orders.paid_amount'),
                  value: orderMoney(context, order.paidAmount!),
                ),
              if (order.companyName != null)
                _Detail(
                  label: context.tr('customer_garage.details.company_label'),
                  value: order.companyName!,
                ),
              if (order.transmissionType != null)
                _Detail(
                  label: context.tr('vehicle.transmission'),
                  value: context.tr('vehicle.${order.transmissionType}'),
                ),
              if (order.colorName != null)
                _Detail(
                  label: context.tr('customer_garage.details.color_label'),
                  value: order.colorName!,
                ),
              if (order.fuelTypeName != null)
                _Detail(
                  label: context.tr('customer_garage.details.fuel_type_label'),
                  value: order.fuelTypeName!,
                ),
              if (order.notes != null)
                _Detail(label: context.tr('orders.notes'), value: order.notes!),
              if (order.imagePaths.isNotEmpty) ...[
                Text(context.tr('orders.photo'), style: text.titleSmall),
                const SizedBox(height: 8),
                for (final path in order.imagePaths) OrderPhoto(path: path),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _OfferPreview extends StatelessWidget {
  const _OfferPreview({
    required this.order,
    required this.offer,
    this.selected = false,
  });
  final CustomerOrder order;
  final CustomerOrderOffer offer;
  final bool selected;
  @override
  Widget build(BuildContext context) => OctoGearSurfaceCard(
    key: ValueKey('request-offer-${offer.id}'),
    padding: const EdgeInsets.all(16),
    onTap: () => CustomerOfferDetailsRoute(
      orderId: order.id,
      offerId: offer.id,
    ).push<void>(context),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                offer.store?.name ?? context.tr('orders.store_unavailable'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Text(
                orderMoney(context, offer.totalPrice),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                context.tr(
                  selected
                      ? 'orders.offer_selected'
                      : 'orders.offer_${offer.status.name}',
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: selected ? OctoGearColors.success : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.arrow_forward_rounded, size: 20),
      ],
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 3),
        Text(value),
      ],
    ),
  );
}
