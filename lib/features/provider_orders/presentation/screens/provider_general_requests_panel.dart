import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../controllers/provider_general_requests_providers.dart';
import '../widgets/provider_city_filter.dart';
import '../widgets/provider_request_widgets.dart';

class ProviderGeneralRequestsPanel extends ConsumerWidget {
  const ProviderGeneralRequestsPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(providerGeneralRequestsProvider);
    final cityId = ref.watch(providerOrderCityProvider);
    final session = ref.watch(sessionControllerProvider).asData?.value;
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(providerGeneralRequestsProvider.notifier).refresh(),
      child: CustomScrollView(
        key: ValueKey((session, cityId)),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(child: ProviderCityFilter()),
          ),
          ...requests.when<List<Widget>>(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: context.tr('provider_requests.loading'),
                    ),
                  ),
                ),
              ),
            ],
            error: (error, _) => [
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: ProviderRequestError(
                    error: error,
                    onRetry: () =>
                        ref.invalidate(providerGeneralRequestsProvider),
                  ),
                ),
              ),
            ],
            data: (data) => [
              SliverPadding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr(
                            'provider_requests.results',
                            args: ['${data.page.total}'],
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: context.tr('provider_requests.refresh'),
                        onPressed: () =>
                            ref.invalidate(providerGeneralRequestsProvider),
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
              ),
              if (data.page.items.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const Icon(Icons.search_off_outlined, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          context.tr('provider_requests.empty'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr('provider_requests.empty_body'),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.builder(
                  itemCount: data.page.items.length,
                  itemBuilder: (context, index) {
                    final item = data.page.items[index];
                    return ProviderRequestCard(
                      key: ValueKey('provider-request-${item.id}'),
                      request: item,
                      onTap: () => ProviderGeneralRequestRoute(
                        orderId: item.id,
                      ).push<void>(context),
                    );
                  },
                ),
              ),
              if (data.nextPageError != null)
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverToBoxAdapter(
                    child: ProviderRequestError(
                      error: data.nextPageError!,
                      onRetry: () => ref
                          .read(providerGeneralRequestsProvider.notifier)
                          .loadMore(),
                    ),
                  ),
                ),
              if (data.page.hasMore && data.nextPageError == null)
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverToBoxAdapter(
                    child: data.loadingMore
                        ? const Center(child: CircularProgressIndicator())
                        : OutlinedButton(
                            key: const Key('provider-requests-more'),
                            onPressed: () => ref
                                .read(providerGeneralRequestsProvider.notifier)
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
