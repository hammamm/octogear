import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/customer_order.dart';
import '../controllers/customer_orders_providers.dart';
import '../controllers/offer_action_controller.dart';
import '../widgets/offer_action_feedback.dart';
import '../widgets/order_widgets.dart';

class RefuseCustomerOfferScreen extends ConsumerStatefulWidget {
  const RefuseCustomerOfferScreen({
    required this.orderId,
    required this.offerId,
    super.key,
  });
  final int orderId, offerId;
  @override
  ConsumerState<RefuseCustomerOfferScreen> createState() =>
      _RefuseCustomerOfferState();
}

class _RefuseCustomerOfferState
    extends ConsumerState<RefuseCustomerOfferScreen> {
  final _note = TextEditingController();
  final _form = GlobalKey<FormState>();
  String? _reason;
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(customerOrderProvider(widget.orderId));
    final action = ref.watch(offerActionProvider(widget.orderId));
    final controller = ref.read(offerActionProvider(widget.orderId).notifier);
    final enabled =
        !action.busy && !action.needsRefresh && action.result == null;
    return PopScope(
      canPop: !action.busy,
      child: ListView(
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
                          : CustomerOfferDetailsRoute(
                              orderId: widget.orderId,
                              offerId: widget.offerId,
                            ).go(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('offer_flow.refuse_title'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                  .where((item) => item.id == widget.offerId)
                  .firstOrNull;
              if (offer == null || !canRespondToOffer(order, offer)) {
                return [Text(context.tr('offer_flow.unavailable_hint'))];
              }
              return [
                OctoGearSurfaceCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.store?.name ??
                            context.tr('orders.store_unavailable'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(orderTitle(context, order)),
                      const SizedBox(height: 8),
                      Text(
                        orderMoney(context, offer.totalPrice),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(context.tr('offer_flow.refuse_hint')),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final reason in ['price', 'fit', 'not_needed'])
                      ChoiceChip(
                        label: Text(context.tr('offer_flow.reason_$reason')),
                        selected: _reason == reason,
                        onSelected: enabled
                            ? (selected) => setState(
                                () => _reason = selected ? reason : null,
                              )
                            : null,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Form(
                  key: _form,
                  child: TextFormField(
                    key: const ValueKey('offer-refusal-note'),
                    controller: _note,
                    enabled: enabled,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 800,
                    decoration: InputDecoration(
                      labelText: context.tr('offer_flow.optional_note'),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) =>
                        (value?.trim().runes.length ?? 0) > 800
                        ? context.tr('offer_flow.note_too_long')
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  key: const ValueKey('offer-confirm-refuse'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: OctoGearColors.error,
                    side: const BorderSide(color: OctoGearColors.error),
                  ),
                  onPressed: !enabled
                      ? null
                      : () async {
                          if (!(_form.currentState?.validate() ?? false)) {
                            return;
                          }
                          final reason = [
                            if (_reason != null)
                              context.tr('offer_flow.reason_$_reason'),
                            if (_note.text.trim().isNotEmpty) _note.text.trim(),
                          ].join('\n');
                          final success = await controller.submit(
                            offer: offer,
                            accept: false,
                            reason: reason,
                          );
                          if (success && context.mounted) {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              CustomerOfferDetailsRoute(
                                orderId: widget.orderId,
                                offerId: widget.offerId,
                              ).go(context);
                            }
                          }
                        },
                  icon: action.busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.close_rounded),
                  label: Text(context.tr('offer_flow.confirm_refuse')),
                ),
                TextButton(
                  onPressed: action.busy
                      ? null
                      : () => context.canPop()
                            ? context.pop()
                            : CustomerOfferDetailsRoute(
                                orderId: widget.orderId,
                                offerId: widget.offerId,
                              ).go(context),
                  child: Text(context.tr('offer_flow.keep_offer')),
                ),
              ];
            },
          ),
          OfferActionFeedback(state: action, onRefresh: controller.refresh),
        ],
      ),
    );
  }
}
