import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/routing/app_routes.dart';
import '../controllers/provider_offers_providers.dart';
import '../widgets/provider_offer_widgets.dart';

class ProviderOffersPanel extends ConsumerWidget {
  const ProviderOffersPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(providerOffersProvider);
    Future<void> refresh() async {
      ref.invalidate(providerOffersProvider);
      try {
        await ref.read(providerOffersProvider.future);
      } catch (_) {
        /* Rendered by AsyncValue. */
      }
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: CustomScrollView(
        key: const PageStorageKey('provider-offers'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(child: Text(context.tr('provider_offers.intro'))),
                  IconButton(
                    onPressed: offers.isLoading ? null : refresh,
                    tooltip: context.tr('provider_offers.refresh'),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
          ),
          ...offers.when<List<Widget>>(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => [
              const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (error, _) => [
              SliverToBoxAdapter(
                child: ProviderOfferError(error: error, retry: refresh),
              ),
            ],
            data: (data) => [
              if (data.page.items.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      context.tr('provider_offers.empty'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.builder(
                  itemCount: data.page.items.length,
                  itemBuilder: (context, i) {
                    final offer = data.page.items[i];
                    return ProviderOfferCard(
                      key: ValueKey('provider-offer-${offer.id}'),
                      offer: offer,
                      open: () => ProviderOfferRoute(
                        offerId: offer.id,
                      ).push<void>(context),
                    );
                  },
                ),
              ),
              if (data.error != null)
                SliverToBoxAdapter(
                  child: ProviderOfferError(
                    error: data.error!,
                    retry: () =>
                        ref.read(providerOffersProvider.notifier).loadMore(),
                  ),
                ),
              if (data.page.hasMore && data.error == null)
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverToBoxAdapter(
                    child: data.loadingMore
                        ? const Center(child: CircularProgressIndicator())
                        : OutlinedButton(
                            onPressed: () => ref
                                .read(providerOffersProvider.notifier)
                                .loadMore(),
                            child: Text(
                              context.tr('provider_requests.load_more'),
                            ),
                          ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ],
      ),
    );
  }
}
