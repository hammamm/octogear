import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../../../core/widgets/authenticated_network_image.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/customer_order.dart';
import '../controllers/customer_orders_providers.dart';
import '../widgets/order_widgets.dart';

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
                        label: context.tr(
                          'customer_garage.details.company_label',
                        ),
                        value: order.companyName!,
                      ),
                    if (order.transmissionType != null)
                      _Info(
                        label: context.tr('vehicle.transmission'),
                        value: context.tr('vehicle.${order.transmissionType}'),
                      ),
                    if (order.colorName != null)
                      _Info(
                        label: context.tr(
                          'customer_garage.details.color_label',
                        ),
                        value: order.colorName!,
                      ),
                    if (order.fuelTypeName != null)
                      _Info(
                        label: context.tr(
                          'customer_garage.details.fuel_type_label',
                        ),
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
                              (order.requestedUnitPrice ??
                                  order.listedUnitPrice)!,
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
                      for (final path in order.imagePaths)
                        _OrderPhoto(path: path),
                    ],
                  ],
                ),
              ),
              if (order.isGeneral) ...[
                const SizedBox(height: 24),
                Text(
                  context.tr(
                    'orders.offers_title',
                    args: [orderNumber(context, order.offersCount)],
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(context.tr('orders.offers_description')),
                const SizedBox(height: 16),
                if (order.offers.isEmpty)
                  OrdersFeedback(
                    title: context.tr('orders.no_offers_title'),
                    message: context.tr(
                      order.status == CustomerOrderStatus.pending
                          ? 'orders.no_offers_pending'
                          : 'orders.no_offers_other',
                    ),
                    icon: Icons.mark_email_unread_outlined,
                  ),
                for (final offer in order.offers)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: 12),
                    child: _OfferCard(offer: offer, order: order),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
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

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer, required this.order});
  final CustomerOrderOffer offer;
  final CustomerOrder order;
  @override
  Widget build(BuildContext context) {
    final selected = order.acceptedOfferId == offer.id;
    return OctoGearSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            offer.store?.name ?? context.tr('orders.store_unavailable'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              selected
                  ? 'orders.offer_selected'
                  : 'orders.offer_${offer.status.name}',
            ),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected
                  ? OctoGearColors.success
                  : OctoGearColors.structuralGray,
            ),
          ),
          const Divider(height: 24),
          Text(
            context.tr(
              'orders.offer_total',
              args: [orderMoney(context, offer.totalPrice)],
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (offer.notes != null) ...[
            const SizedBox(height: 12),
            Text(offer.notes!),
          ],
          for (final path in offer.imagePaths) _OrderPhoto(path: path),
          if (offer.rejectionReason != null) ...[
            const SizedBox(height: 12),
            Text(
              context.tr(
                'orders.rejection_reason',
                args: [offer.rejectionReason!],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderPhoto extends StatelessWidget {
  const _OrderPhoto({required this.path});
  final String path;
  Widget _image(BuildContext context) => AuthenticatedNetworkImage(
    apiPath: path,
    fit: BoxFit.contain,
    semanticLabel: context.tr('orders.photo'),
    loadingBuilder: (_, child, progress) => progress == null
        ? child
        : const Center(child: CircularProgressIndicator()),
    errorBuilder: (_, _, _) => Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          context.tr('orders.photo_error'),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(height: 220, child: _image(context)),
      ),
      TextButton.icon(
        icon: const Icon(Icons.zoom_in_rounded),
        label: Text(context.tr('orders.enlarge_photo')),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (dialogContext) => Dialog.fullscreen(
            child: SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: IconButton(
                      tooltip: MaterialLocalizations.of(
                        dialogContext,
                      ).closeButtonTooltip,
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                  Expanded(
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Center(child: _image(dialogContext)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
