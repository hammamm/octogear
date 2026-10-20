import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../../domain/entities/provider_offer.dart';
import '../controllers/provider_offers_providers.dart';
import 'provider_offer_widgets.dart';

/// Keeps editing within the Chats branch so the conversation and draft survive.
class ProviderChatOffers extends ConsumerStatefulWidget {
  const ProviderChatOffers({
    required this.conversationId,
    this.currentOfferId,
    super.key,
  });
  final int conversationId;
  final int? currentOfferId;

  @override
  ConsumerState<ProviderChatOffers> createState() => _ProviderChatOffersState();
}

class _ProviderChatOffersState extends ConsumerState<ProviderChatOffers> {
  bool _opening = false;

  void _refresh() =>
      ref.invalidate(providerChatOffersProvider(widget.conversationId));

  Future<void> _open(ProviderOffersPage page) async {
    if (_opening) return;
    setState(() => _opening = true);
    FocusScope.of(context).unfocus();
    final session = ref.read(sessionControllerProvider).asData?.value;
    try {
      final offer = page.total == 1 && !page.hasMore && page.items.length == 1
          ? page.items.single
          : await showModalBottomSheet<ProviderOffer>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              showDragHandle: true,
              builder: (_) => _OfferChooser(
                conversationId: widget.conversationId,
                currentOfferId: widget.currentOfferId,
              ),
            );
      if (!mounted ||
          offer == null ||
          !identical(
            session,
            ref.read(sessionControllerProvider).asData?.value,
          )) {
        return;
      }
      // Reload on entry: a customer may have selected the offer since the list read.
      ref.invalidate(providerOfferProvider(offer.id));
      await ProviderChatOfferFormRoute(
        orderId: offer.orderId,
        offerId: offer.id,
      ).push<void>(context);
      if (mounted) _refresh();
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final offers = ref.watch(providerChatOffersProvider(widget.conversationId));
    // This optional shortcut must not reserve space until offers are available.
    if (offers.isLoading || offers.asData?.value.page.items.isEmpty == true) {
      return const SizedBox.shrink();
    }
    // Limit the strip's height even with the keyboard and enlarged text.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 160),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 8, 6),
          child: offers.when(
            skipLoadingOnRefresh: false,
            loading: () => const SizedBox.shrink(),
            error: (_, _) => Row(
              children: [
                Expanded(child: Text(context.tr('chat_offers.failed'))),
                IconButton(
                  onPressed: _refresh,
                  tooltip: context.tr('common.retry'),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            data: (state) {
              final page = state.page;
              final single =
                  page.total == 1 && !page.hasMore && page.items.length == 1
                  ? page.items.single
                  : null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          key: const Key('chat-edit-offer'),
                          onPressed: _opening ? null : () => _open(page),
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(
                            context.tr(
                              single != null
                                  ? 'chat_offers.edit'
                                  : 'chat_offers.choose',
                              args: single != null ? [] : ['${page.total}'],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _opening ? null : _refresh,
                        tooltip: context.tr('chat_offers.refresh'),
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  if (single != null &&
                      MediaQuery.viewInsetsOf(context).bottom == 0)
                    Text(
                      '${single.partName ?? context.tr('provider_requests.unnamed')} · '
                      '${single.storeName}\n'
                      '${context.tr('chat_offers.identity', args: ['${single.orderId}', '${single.id}'])} · '
                      '${offerMoney(context, single.price)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OfferChooser extends ConsumerWidget {
  const _OfferChooser({required this.conversationId, this.currentOfferId});
  final int conversationId;
  final int? currentOfferId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = providerChatOffersProvider(conversationId);
    final offers = ref.watch(provider);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('chat_offers.title'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const CloseButton(),
              ],
            ),
          ),
          Expanded(
            child: offers.when(
              skipLoadingOnRefresh: false,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => SingleChildScrollView(
                child: ProviderOfferError(
                  error: error,
                  retry: () => ref.invalidate(provider),
                ),
              ),
              data: (state) => ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(context.tr('chat_offers.hint')),
                  const SizedBox(height: 16),
                  if (state.page.items.isEmpty)
                    Text(context.tr('chat_offers.empty')),
                  for (final offer in state.page.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OctoGearSurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (offer.id == currentOfferId)
                              Text(
                                context.tr('chat_offers.current'),
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            Text(
                              offer.partName ??
                                  context.tr('provider_requests.unnamed'),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              context.tr(
                                'chat_offers.identity',
                                args: ['${offer.orderId}', '${offer.id}'],
                              ),
                            ),
                            Text(offer.storeName),
                            Text(
                              offerMoney(context, offer.price),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            OutlinedButton.icon(
                              key: ValueKey('chat-choose-offer-${offer.id}'),
                              onPressed: offer.canEdit
                                  ? () => Navigator.pop(context, offer)
                                  : null,
                              icon: const Icon(Icons.edit_outlined),
                              label: Text(context.tr('chat_offers.edit')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (state.error != null)
                    Text(offerFailure(context, state.error!)),
                  if (state.loadingMore)
                    const Center(child: CircularProgressIndicator())
                  else if (state.page.hasMore)
                    OutlinedButton(
                      onPressed: ref.read(provider.notifier).loadMore,
                      child: Text(
                        context.tr(
                          state.error == null
                              ? 'chat_offers.more'
                              : 'common.retry',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
