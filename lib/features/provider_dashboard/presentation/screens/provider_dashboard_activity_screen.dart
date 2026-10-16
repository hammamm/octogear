import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/provider_dashboard.dart';
import '../controllers/provider_dashboard_providers.dart';
import '../widgets/provider_dashboard_widgets.dart';

class ProviderDashboardActivityScreen extends ConsumerWidget {
  const ProviderDashboardActivityScreen({
    required this.section,
    this.storeId,
    super.key,
  });
  final ProviderDashboardSection section;
  final int? storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (storeId: storeId, section: section);
    final provider = providerDashboardActivityProvider(query);
    final result = ref.watch(provider);
    Future<void> refresh() async {
      ref.invalidate(provider);
      ref.invalidate(providerDashboardProvider);
      try {
        await ref.read(provider.future);
      } catch (_) {
        /* Rendered below. */
      }
    }

    final sectionKey = dashboardSectionKey(section);
    final dashboard = ref.watch(providerDashboardProvider);
    String? storeName;
    if (!dashboard.isLoading && !dashboard.hasError) {
      for (final store
          in dashboard.asData?.value.stores ?? <ProviderDashboardStore>[]) {
        if (store.id == storeId) {
          storeName = store.name;
        }
      }
    }
    final scope = storeId == null
        ? context.tr('provider_dashboard.all_stores')
        : storeName ??
              context.tr('provider_dashboard.store_number', args: ['$storeId']);
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        key: PageStorageKey('dashboard-activity-${section.name}-$storeId'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
        children: [
          DashboardHeader(
            titleKey: 'provider_dashboard.$sectionKey',
            showBack: true,
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('provider_dashboard.store_scope', args: [scope]),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('provider_dashboard.${sectionKey}_hint'),
                ),
              ),
              IconButton(
                onPressed: result.isLoading ? null : refresh,
                tooltip: context.tr('provider_dashboard.refresh'),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...result.when<List<Widget>>(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            loading: () => [const Center(child: CircularProgressIndicator())],
            error: (error, _) => [DashboardError(error: error, retry: refresh)],
            data: (state) => [
              if (state.page.items.isEmpty)
                Text(context.tr('provider_dashboard.${sectionKey}_empty')),
              for (final order in state.page.items)
                DashboardOrderCard(
                  key: ValueKey('activity-order-${order.id}'),
                  order: order,
                ),
              if (state.error != null)
                DashboardError(
                  error: state.error!,
                  retry: () => ref.read(provider.notifier).loadMore(),
                )
              else if (state.page.hasMore)
                OutlinedButton(
                  onPressed: state.loadingMore
                      ? null
                      : () => ref.read(provider.notifier).loadMore(),
                  child: state.loadingMore
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.tr('provider_dashboard.load_more')),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
