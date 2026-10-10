import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/customer_order.dart';
import '../controllers/customer_orders_providers.dart';
import '../controllers/offer_action_controller.dart';
import '../widgets/offer_action_feedback.dart';
import '../widgets/order_photo.dart';
import '../widgets/order_widgets.dart';

class CustomerOfferDetailsScreen extends ConsumerWidget {
  const CustomerOfferDetailsScreen({
    required this.orderId,
    required this.offerId,
    super.key,
  });
  final int orderId, offerId;

  Future<void> _accept(
    BuildContext context,
    WidgetRef ref,
    CustomerOrderOffer offer,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('offer_flow.confirm_accept')),
        content: Text(
          dialogContext.tr(
            'offer_flow.accept_explanation',
            args: [
              offer.store?.name ?? dialogContext.tr('orders.store_unavailable'),
              orderMoney(dialogContext, offer.totalPrice),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.tr('offer_flow.keep_reviewing')),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.tr('offer_flow.accept')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref
        .read(offerActionProvider(orderId).notifier)
        .submit(offer: offer, accept: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(customerOrderProvider(orderId));
    final action = ref.watch(offerActionProvider(orderId));
    final controller = ref.read(offerActionProvider(orderId).notifier);
    return PopScope(
      canPop: !action.busy,
      child: RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView(
          key: PageStorageKey('offer-details-$orderId-$offerId'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 28),
          children: [
            Row(
              children: [
                IconButton(
                  icon: const BackButtonIcon(),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: action.busy
                      ? null
                      : () => context.canPop()
                            ? context.pop()
                            : CustomerOrderDetailsRoute(
                                orderId: orderId,
                              ).go(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('offer_flow.title'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const AppLanguageToggleButton(compact: true),
              ],
            ),
            const SizedBox(height: 16),
            if (action.result == OfferActionResult.accepted)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OctoGearFeedbackBanner(
                  message: context.tr('offer_flow.accepted'),
                  tone: OctoGearFeedbackTone.success,
                ),
              ),
            if (action.result == OfferActionResult.rejected)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OctoGearFeedbackBanner(
                  message: context.tr('offer_flow.refused'),
                  tone: OctoGearFeedbackTone.information,
                ),
              ),
            ...order.when(
              skipLoadingOnRefresh: false,
              loading: () => [const Center(child: CircularProgressIndicator())],
              error: (error, _) => [
                OrdersFeedback(
                  title: context.tr('orders.error_title'),
                  message: ordersErrorMessage(context, error),
                  icon: Icons.cloud_off_outlined,
                  action: context.tr('common.retry'),
                  onAction: action.busy ? null : controller.refresh,
                ),
              ],
              data: (order) {
                final offer = order.offers
                    .where((item) => item.id == offerId)
                    .firstOrNull;
                if (!order.isGeneral || offer == null) {
                  return [
                    OrdersFeedback(
                      title: context.tr('offer_flow.unavailable'),
                      message: context.tr('offer_flow.unavailable_hint'),
                      icon: Icons.receipt_long_outlined,
                    ),
                  ];
                }
                final selected = order.acceptedOfferId == offer.id;
                final enabled =
                    !action.busy &&
                    !action.needsRefresh &&
                    action.result == null;
                return [
                  OctoGearSurfaceCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.storefront_outlined,
                              color: OctoGearColors.navy,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                offer.store?.name ??
                                    context.tr('orders.store_unavailable'),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          orderTitle(context, order),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (orderCar(order).isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(orderCar(order)),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          context.tr('home.offer_total_label'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          orderMoney(context, offer.totalPrice),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr(
                            selected
                                ? 'orders.offer_selected'
                                : 'orders.offer_${offer.status.name}',
                          ),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: selected
                                    ? OctoGearColors.success
                                    : OctoGearColors.structuralGray,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (canRespondToOffer(order, offer)) ...[
                    OutlinedButton.icon(
                      key: const ValueKey('offer-accept'),
                      onPressed: enabled
                          ? () => _accept(context, ref, offer)
                          : null,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: OctoGearColors.surface,
                        foregroundColor: OctoGearColors.success,
                        side: const BorderSide(color: OctoGearColors.success),
                      ),
                      icon: const Icon(Icons.check_rounded),
                      label: Text(context.tr('offer_flow.accept')),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (selected)
                        FilledButton.icon(
                          key: const Key('offer-track-order'),
                          onPressed: action.busy
                              ? null
                              : () => CustomerOrderDetailsRoute(
                                  orderId: orderId,
                                ).go(context),
                          icon: const Icon(Icons.receipt_long_outlined),
                          label: Text(context.tr('order_flow.view_order')),
                        ),
                      OutlinedButton.icon(
                        key: const ValueKey('offer-chat'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onPressed: action.busy
                            ? null
                            : () => CustomerOfferChatRoute(
                                orderId: orderId,
                                offerId: offerId,
                              ).go(context),
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 20,
                        ),
                        label: Text(context.tr('offer_flow.chat')),
                      ),
                      if (canRespondToOffer(order, offer))
                        TextButton.icon(
                          key: const ValueKey('offer-refuse'),
                          onPressed: enabled
                              ? () => RefuseCustomerOfferRoute(
                                  orderId: orderId,
                                  offerId: offerId,
                                ).push<void>(context)
                              : null,
                          style: TextButton.styleFrom(
                            foregroundColor: OctoGearColors.error,
                            minimumSize: const Size(48, 48),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          label: Text(context.tr('offer_flow.refuse')),
                        ),
                    ],
                  ),
                  if (action.busy)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: LinearProgressIndicator(),
                    ),
                  if (offer.notes != null ||
                      offer.imagePaths.isNotEmpty ||
                      offer.rejectionReason != null) ...[
                    const SizedBox(height: 20),
                    OctoGearSurfaceCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (offer.notes != null) ...[
                            Text(
                              context.tr('offer_flow.store_notes'),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(offer.notes!),
                          ],
                          if (offer.rejectionReason != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              context.tr(
                                'orders.rejection_reason',
                                args: [offer.rejectionReason!],
                              ),
                            ),
                          ],
                          for (final path in offer.imagePaths)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: OrderPhoto(path: path),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: action.busy
                        ? null
                        : () => CustomerOrderDetailsRoute(
                            orderId: orderId,
                          ).go(context),
                    icon: const Icon(Icons.description_outlined, size: 20),
                    label: Text(context.tr('offer_flow.related_request')),
                  ),
                ];
              },
            ),
            OfferActionFeedback(state: action, onRefresh: controller.refresh),
          ],
        ),
      ),
    );
  }
}
