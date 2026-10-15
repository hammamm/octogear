import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/widgets/authenticated_network_image.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/provider_offer.dart';
import '../controllers/provider_offers_providers.dart';
import '../widgets/provider_offer_widgets.dart';

class ProviderOfferScreen extends ConsumerWidget {
  const ProviderOfferScreen({required this.offerId, super.key});
  final int offerId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = providerOfferProvider(offerId);
    final result = ref.watch(provider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const BackButton(),
            Expanded(
              child: Text(
                context.tr('provider_offers.number', args: ['$offerId']),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: context.tr('provider_offers.refresh'),
              onPressed: () => ref.invalidate(provider),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...result.when<List<Widget>>(
          skipLoadingOnReload: false,
          skipLoadingOnRefresh: false,
          loading: () => [const Center(child: CircularProgressIndicator())],
          error: (error, _) => [
            ProviderOfferError(
              error: error,
              retry: () => ref.invalidate(provider),
            ),
          ],
          data: (offer) => [
            OctoGearSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    offer.partName ?? context.tr('provider_requests.unnamed'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    context.tr(
                      'provider_requests.request_number',
                      args: ['${offer.orderId}'],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(offer.storeName),
                  Text(
                    offerMoney(context, offer.price),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(offerStatus(context, offer.status)),
                  const SizedBox(height: 16),
                  Text(context.tr('provider_offers.notes')),
                  SelectableText(
                    offer.notes ?? context.tr('provider_requests.not_provided'),
                  ),
                  if (offer.rejectionReason != null) ...[
                    const SizedBox(height: 16),
                    Text(context.tr('provider_offers.rejection_reason')),
                    SelectableText(offer.rejectionReason!),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    DateFormat.yMMMd(
                      context.locale.toLanguageTag(),
                    ).format(offer.createdAt.toLocal()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _OfferActions(offer: offer),
            for (final path in offer.imagePaths)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: InteractiveViewer(
                    child: AuthenticatedNetworkImage(
                      apiPath: path,
                      fit: BoxFit.contain,
                      semanticLabel: context.tr('provider_offers.photo'),
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
        ),
      ],
    );
  }
}

class _OfferActions extends ConsumerWidget {
  const _OfferActions({required this.offer});
  final ProviderOffer offer;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = providerOfferActionsProvider((
      orderId: offer.orderId,
      offerId: offer.id,
    ));
    final action = ref.watch(provider);
    void removed() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('provider_offers.withdrawn'))),
      );
      Navigator.of(context).pop();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (action.error != null && !action.uncertain)
          Text(offerFailure(context, action.error!)),
        if (action.uncertain) ...[
          Text(context.tr('provider_offers.uncertain')),
          OutlinedButton(
            onPressed: action.busy
                ? null
                : () async {
                    await ref.read(provider.notifier).check();
                    if (context.mounted && ref.read(provider).withdrawn) {
                      removed();
                    }
                  },
            child: Text(context.tr('provider_offers.check')),
          ),
        ],
        if (action.busy) const LinearProgressIndicator(),
        if (offer.canEdit)
          FilledButton.icon(
            key: const Key('provider-offer-edit'),
            onPressed: action.busy || action.uncertain
                ? null
                : () => ProviderOfferFormRoute(
                    orderId: offer.orderId,
                    offerId: offer.id,
                  ).push<void>(context),
            icon: const Icon(Icons.edit_outlined),
            label: Text(context.tr('provider_offers.edit')),
          ),
        if (offer.canWithdraw)
          OutlinedButton.icon(
            key: const Key('provider-offer-withdraw'),
            onPressed: action.busy || action.uncertain
                ? null
                : () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(context.tr('provider_offers.withdraw')),
                        content: Text(
                          context.tr('provider_offers.withdraw_confirm'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(context.tr('common.cancel')),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(context.tr('provider_offers.withdraw')),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true || !context.mounted) return;
                    final done = await ref
                        .read(provider.notifier)
                        .withdraw(offer);
                    if (done && context.mounted) removed();
                  },
            icon: const Icon(Icons.delete_outline),
            label: Text(context.tr('provider_offers.withdraw')),
          ),
        if (!offer.canEdit && !offer.canWithdraw)
          Text(context.tr('provider_offers.locked')),
      ],
    );
  }
}
