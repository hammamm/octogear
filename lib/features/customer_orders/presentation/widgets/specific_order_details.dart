import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/customer_order.dart';
import 'order_widgets.dart';
import 'order_photo.dart';

class SpecificOrderDetails extends StatelessWidget {
  const SpecificOrderDetails({required this.order, super.key});
  final CustomerOrder order;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      OctoGearSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('orders.reference', args: ['${order.id}']),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                OrderStatusBadge(order: order),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('orders.type_${order.type.name}'),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Text(
              orderTitle(context, order),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (orderCar(order).isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(orderCar(order)),
            ],
            const Divider(height: 32),
            _Info(
              label: context.tr('orders.created'),
              value: DateFormat.yMMMd(
                context.locale.toLanguageTag(),
              ).add_jm().format(order.createdAt.toLocal()),
            ),
            if (!order.isGeneral)
              _Info(
                label: context.tr('part_request.quantity'),
                value: orderNumber(context, order.quantity!),
              ),
            if (order.companyName != null)
              _Info(
                label: context.tr('customer_garage.details.company_label'),
                value: order.companyName!,
              ),
            if (order.transmissionType != null)
              _Info(
                label: context.tr('vehicle.transmission'),
                value: context.tr('vehicle.${order.transmissionType}'),
              ),
            if (order.colorName != null)
              _Info(
                label: context.tr('customer_garage.details.color_label'),
                value: order.colorName!,
              ),
            if (order.fuelTypeName != null)
              _Info(
                label: context.tr('customer_garage.details.fuel_type_label'),
                value: order.fuelTypeName!,
              ),
            if (order.partNumber != null && !order.isGeneral)
              _Info(
                label: context.tr('storefront.car.part_number'),
                value: order.partNumber!,
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      OctoGearSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.storefront_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr(
                      order.isGeneral
                          ? 'orders.selected_store'
                          : 'orders.store',
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              order.displayStore?.name ??
                  context.tr(
                    order.isGeneral && !order.hasSelectedOffer
                        ? 'orders.no_selected_store'
                        : 'orders.store_unavailable',
                  ),
            ),
            const Divider(height: 28),
            Text(
              orderPriceLabel(context, order),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Text(
              order.displayTotal == null
                  ? context.tr(
                      order.isGeneral
                          ? 'orders.no_selected_price'
                          : 'orders.price_unavailable',
                    )
                  : orderMoney(context, order.displayTotal!),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (!order.isGeneral &&
                order.paidAmount == null &&
                (order.requestedUnitPrice ?? order.listedUnitPrice) !=
                    null) ...[
              const SizedBox(height: 8),
              Text(
                context.tr(
                  'orders.unit_price',
                  args: [
                    orderMoney(
                      context,
                      (order.requestedUnitPrice ?? order.listedUnitPrice)!,
                    ),
                  ],
                ),
              ),
              if (order.requestedUnitPrice == null) ...[
                const SizedBox(height: 8),
                Text(
                  context.tr('orders.listing_note'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      OctoGearSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('orders.notes'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(order.notes ?? context.tr('orders.no_notes')),
            if (order.imagePaths.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                context.tr('orders.photo'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              for (final path in order.imagePaths) OrderPhoto(path: path),
            ],
          ],
        ),
      ),
    ],
  );
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 3),
        Text(value),
      ],
    ),
  );
}
