import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/widgets/authenticated_network_image.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/provider_managed_order.dart';
import '../controllers/provider_managed_orders_providers.dart';
import '../widgets/provider_managed_order_widgets.dart';
import '../widgets/provider_offer_widgets.dart';

class ProviderManagedOrderScreen extends ConsumerWidget {
  const ProviderManagedOrderScreen({
    required this.orderId,
    required this.kind,
    super.key,
  });
  final int orderId;
  final ProviderOrderKind kind;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = providerManagedOrderProvider((kind: kind, id: orderId));
    final result = ref.watch(provider);
    final actionProvider = providerDirectOrderActionsProvider(orderId);
    final action = kind == ProviderOrderKind.direct
        ? ref.watch(actionProvider)
        : const ProviderDirectOrderActionState();
    Future<void> refresh() async {
      if (action.busy) return;
      ref.invalidate(provider);
      try {
        await ref.read(provider.future);
      } catch (_) {
        /* Rendered below. */
      }
    }

    Future<void> respond(ProviderManagedOrder order, bool accept) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          scrollable: true,
          title: Text(
            dialogContext.tr('provider_orders.${accept ? 'accept' : 'reject'}'),
          ),
          content: Text(
            dialogContext.tr(
              'provider_orders.${accept ? 'accept_confirm' : 'reject_confirm'}',
              args: accept
                  ? [
                      order.storeName,
                      '${order.quantity}',
                      offerMoney(dialogContext, order.total!),
                    ]
                  : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(dialogContext.tr('common.cancel')),
            ),
            FilledButton(
              key: const Key('provider-order-confirm'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                dialogContext.tr(
                  'provider_orders.${accept ? 'accept' : 'reject'}',
                ),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true ||
          !context.mounted ||
          !identical(ref.read(provider).asData?.value, order)) {
        return;
      }
      final updated = await ref
          .read(actionProvider.notifier)
          .respond(order, accept: accept);
      if (updated != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr('provider_orders.updated'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        key: PageStorageKey('provider-${kind.name}-detail-$orderId'),
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Row(
            children: [
              const BackButton(),
              Expanded(
                child: Text(
                  context.tr(
                    'provider_requests.request_number',
                    args: ['$orderId'],
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: result.isLoading || action.busy ? null : refresh,
                tooltip: context.tr('provider_requests.refresh'),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...result.when<List<Widget>>(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => [const Center(child: CircularProgressIndicator())],
            error: (error, _) => [
              ProviderManagedOrderError(error: error, retry: refresh),
            ],
            data: (order) => [
              OctoGearSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      order.partName ?? context.tr('provider_requests.unnamed'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Divider(height: 32),
                    Text(
                      managedOrderStatus(context, order.status),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr(
                        'provider_orders.${switch (order.status) {
                          'pending' => 'pending_help',
                          'awaiting_payment' => 'awaiting_help',
                          'paid' => 'paid_help',
                          'completed' => 'completed_help',
                          'rejected' => 'rejected_help',
                          'cancelled' => 'cancelled_help',
                          _ => 'unknown_help',
                        }}',
                      ),
                    ),
                    const SizedBox(height: 20),
                    ProviderOrderField(
                      'provider_orders.store',
                      order.storeName,
                    ),
                    ProviderOrderField(
                      'provider_requests.vehicle',
                      managedOrderVehicle(order),
                    ),
                    if (order.partNumber != null)
                      ProviderOrderField(
                        'provider_orders.part_number',
                        order.partNumber,
                      ),
                    ProviderOrderField(
                      'provider_requests.city_filter',
                      order.city,
                    ),
                    if (order.customerName != null)
                      ProviderOrderField(
                        'provider_orders.customer',
                        order.customerName,
                      ),
                    if (order.quantity != null)
                      ProviderOrderField(
                        'provider_orders.quantity',
                        '${order.quantity}',
                      ),
                    if (order.unitPrice != null)
                      ProviderOrderField(
                        'provider_orders.unit_price',
                        offerMoney(context, order.unitPrice!),
                      ),
                    if (order.total != null)
                      ProviderOrderField(
                        'provider_orders.total',
                        offerMoney(context, order.total!),
                      ),
                    if (order.commission != null) ...[
                      const Divider(height: 24),
                      ProviderOrderField(
                        'provider_orders.commission',
                        offerMoney(context, order.commission!),
                      ),
                      ProviderOrderField(
                        'provider_orders.net',
                        offerMoney(context, order.net!),
                      ),
                      Text(
                        context.tr('provider_orders.estimate_notice'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (order.transmission != null)
                      ProviderOrderField(
                        'provider_requests.transmission',
                        switch (order.transmission) {
                          'automatic' => context.tr(
                            'provider_requests.automatic',
                          ),
                          'manual' => context.tr('provider_requests.manual'),
                          _ => order.transmission,
                        },
                      ),
                    if (order.color != null)
                      ProviderOrderField(
                        'provider_requests.color',
                        order.color,
                      ),
                    if (order.fuel != null)
                      ProviderOrderField('provider_requests.fuel', order.fuel),
                    ProviderOrderField(
                      'provider_requests.description',
                      order.description,
                    ),
                    ProviderOrderField(
                      'provider_requests.date',
                      DateFormat.yMMMd(
                        context.locale.toLanguageTag(),
                      ).add_jm().format(order.createdAt.toLocal()),
                    ),
                    Text(
                      context.tr('provider_requests.pickup_notice'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (order.acceptedOfferId != null)
                OutlinedButton.icon(
                  onPressed: () => ProviderOfferRoute(
                    offerId: order.acceptedOfferId!,
                  ).push<void>(context),
                  icon: const Icon(Icons.local_offer_outlined),
                  label: Text(context.tr('provider_orders.accepted_offer')),
                ),
              if (kind == ProviderOrderKind.direct) ...[
                if (action.busy) const LinearProgressIndicator(),
                if (action.uncertain) ...[
                  Text(context.tr('provider_orders.uncertain')),
                  OutlinedButton(
                    key: const Key('provider-order-check'),
                    onPressed: action.busy
                        ? null
                        : () => ref.read(actionProvider.notifier).check(),
                    child: Text(context.tr('provider_orders.check')),
                  ),
                ] else if (action.error != null)
                  ProviderManagedOrderError(
                    error: action.error!,
                    retry: refresh,
                  ),
                if (order.canAccept)
                  FilledButton.icon(
                    key: const Key('provider-order-accept'),
                    onPressed: action.busy || action.uncertain
                        ? null
                        : () => respond(order, true),
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(context.tr('provider_orders.accept')),
                  ),
                if (order.canReject)
                  OutlinedButton.icon(
                    key: const Key('provider-order-reject'),
                    onPressed: action.busy || action.uncertain
                        ? null
                        : () => respond(order, false),
                    icon: const Icon(Icons.cancel_outlined),
                    label: Text(context.tr('provider_orders.reject')),
                  ),
                if (order.status == 'pending' && !order.canAccept)
                  Text(context.tr('provider_orders.cannot_accept')),
                if (order.isPaid)
                  OutlinedButton(
                    onPressed: () => ProviderPaidOrderRoute(
                      orderId: order.id,
                    ).push<void>(context),
                    child: Text(context.tr('provider_orders.payment_details')),
                  ),
              ],
              if (order.imagePaths.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  context.tr('provider_requests.photos'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final path in order.imagePaths)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: InteractiveViewer(
                        child: AuthenticatedNetworkImage(
                          apiPath: path,
                          fit: BoxFit.contain,
                          semanticLabel: context.tr('provider_requests.photo'),
                          errorBuilder: (_, _, _) => Center(
                            child: Text(
                              context.tr('provider_requests.photo_error'),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
