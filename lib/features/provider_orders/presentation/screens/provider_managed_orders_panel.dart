import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/routing/app_routes.dart';
import '../../domain/entities/provider_managed_order.dart';
import '../controllers/provider_managed_orders_providers.dart';
import '../widgets/provider_managed_order_widgets.dart';

class ProviderManagedOrdersPanel extends ConsumerWidget {
  const ProviderManagedOrdersPanel({required this.kind, super.key});
  final ProviderOrderKind kind;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = providerManagedOrderFilterProvider(kind);
    final status = ref.watch(filter);
    final provider = providerManagedOrdersProvider((
      kind: kind,
      status: status,
    ));
    final result = ref.watch(provider);
    final paid = kind == ProviderOrderKind.paid;
    final statuses = paid
        ? <String?>['paid', 'completed']
        : <String?>[
            'pending',
            'awaiting_payment',
            'rejected',
            'cancelled',
            null,
          ];
    Future<void> refresh() async {
      ref.invalidate(provider);
      try {
        await ref.read(provider.future);
      } catch (_) {
        /* Rendered below. */
      }
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: CustomScrollView(
        key: PageStorageKey('provider-${kind.name}-$status'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr(
                            'provider_orders.${paid ? 'paid_intro' : 'direct_intro'}',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: result.isLoading ? null : refresh,
                        tooltip: context.tr('provider_requests.refresh'),
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final value in statuses)
                        ChoiceChip(
                          key: ValueKey(
                            'provider-${kind.name}-filter-${value ?? 'all'}',
                          ),
                          label: Text(
                            value == null
                                ? context.tr('provider_orders.all')
                                : managedOrderStatus(context, value),
                          ),
                          selected: status == value,
                          onSelected: (_) =>
                              ref.read(filter.notifier).select(value),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ...result.when<List<Widget>>(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => [
              const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (error, _) => [
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: ProviderManagedOrderError(
                    error: error,
                    retry: refresh,
                  ),
                ),
              ),
            ],
            data: (data) => [
              if (data.page.items.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      context.tr(
                        'provider_orders.${paid ? 'paid_empty' : 'direct_empty'}',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.builder(
                  itemCount: data.page.items.length,
                  itemBuilder: (context, index) {
                    final order = data.page.items[index];
                    return ProviderManagedOrderCard(
                      key: ValueKey('provider-${kind.name}-order-${order.id}'),
                      order: order,
                      open: () {
                        if (paid) {
                          ProviderPaidOrderRoute(
                            orderId: order.id,
                          ).push<void>(context);
                        } else {
                          ProviderDirectOrderRoute(
                            orderId: order.id,
                          ).push<void>(context);
                        }
                      },
                    );
                  },
                ),
              ),
              if (data.error != null)
                SliverToBoxAdapter(
                  child: ProviderManagedOrderError(
                    error: data.error!,
                    retry: () => ref.read(provider.notifier).loadMore(),
                  ),
                ),
              if (data.page.hasMore && data.error == null)
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverToBoxAdapter(
                    child: data.loadingMore
                        ? const Center(child: CircularProgressIndicator())
                        : OutlinedButton(
                            onPressed: () =>
                                ref.read(provider.notifier).loadMore(),
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
