import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_router.dart';
import '../../../../app/routing/app_routes.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../../authentication/domain/entities/session_outcome.dart';
import '../../../authentication/presentation/controllers/session_controller.dart';
import '../../../provider_dashboard/domain/entities/provider_dashboard.dart';
import '../../../provider_dashboard/presentation/controllers/provider_dashboard_providers.dart';
import '../../../provider_dashboard/presentation/widgets/provider_dashboard_widgets.dart';
import '../../../provider_orders/presentation/widgets/provider_offer_widgets.dart';
import '../widgets/provider_page.dart';

class ProviderDashboardScreen extends ConsumerStatefulWidget {
  const ProviderDashboardScreen({super.key});
  @override
  ConsumerState<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState
    extends ConsumerState<ProviderDashboardScreen>
    with WidgetsBindingObserver {
  late GoRouter _router;
  String _lastPath = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = ref.read(appRouterProvider);
    _lastPath = _router.routeInformationProvider.value.uri.path;
    _router.routeInformationProvider.addListener(_routeChanged);
  }

  void _routeChanged() {
    final path = _router.routeInformationProvider.value.uri.path;
    if (path == const ProviderHomeRoute().location && path != _lastPath) {
      ref.invalidate(providerDashboardProvider);
      ref.invalidate(providerDashboardActivityProvider);
    }
    _lastPath = path;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(providerDashboardProvider);
      ref.invalidate(providerDashboardActivityProvider);
    }
  }

  @override
  void dispose() {
    _router.routeInformationProvider.removeListener(_routeChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(providerDashboardProvider);
    ref.invalidate(providerDashboardActivityProvider);
    try {
      await ref.read(providerDashboardProvider.future);
    } catch (_) {
      /* Rendered below. */
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider).asData?.value;
    final name = session is AuthenticatedSession ? session.user.fullName : '';
    final result = ref.watch(providerDashboardProvider);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            key: const PageStorageKey('provider-dashboard'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
            children: [
              DashboardHeader(
                titleKey: 'provider_portal.dashboard',
                showRefresh: true,
                showNotifications: true,
                onRefresh: result.isLoading ? null : _refresh,
              ),
              const SizedBox(height: 20),
              Text(
                context.tr('provider_portal.welcome', args: [name]),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('provider-shortcut-orders'),
                onPressed: () =>
                    const ProviderOrdersRoute(section: 'general').go(context),
                icon: const Icon(Icons.travel_explore_outlined),
                label: Text(context.tr('provider_dashboard.browse_general')),
              ),
              const SizedBox(height: 12),
              Text(context.tr('provider_dashboard.intro')),
              const SizedBox(height: 24),
              ...result.when<List<Widget>>(
                skipLoadingOnRefresh: false,
                skipLoadingOnReload: false,
                loading: () => [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: context.tr(
                          'provider_dashboard.loading',
                        ),
                      ),
                    ),
                  ),
                ],
                error: (error, _) => [
                  DashboardError(error: error, retry: _refresh),
                  if (ref.watch(providerDashboardFilterProvider).storeId !=
                      null)
                    TextButton(
                      onPressed: () => ref
                          .read(providerDashboardFilterProvider.notifier)
                          .selectStore(null),
                      child: Text(context.tr('provider_dashboard.all_stores')),
                    ),
                ],
                data: (dashboard) => [
                  if (dashboard.stores.isEmpty)
                    OctoGearSurfaceCard(
                      child: Text(context.tr('provider_dashboard.no_stores')),
                    )
                  else ...[
                    DropdownButtonFormField<int>(
                      key: ValueKey(
                        'dashboard-store-${dashboard.selectedStoreId}',
                      ),
                      initialValue: dashboard.selectedStoreId ?? 0,
                      isExpanded: true,
                      isDense: false,
                      itemHeight: null,
                      decoration: InputDecoration(
                        labelText: context.tr(
                          'provider_dashboard.store_filter',
                        ),
                        prefixIcon: const Icon(Icons.storefront_outlined),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              context.tr('provider_dashboard.all_stores'),
                            ),
                          ),
                        ),
                        for (final store in dashboard.stores)
                          DropdownMenuItem(
                            value: store.id,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(store.name),
                            ),
                          ),
                      ],
                      onChanged: (id) => ref
                          .read(providerDashboardFilterProvider.notifier)
                          .selectStore(id == 0 ? null : id),
                    ),
                    const SizedBox(height: 20),
                    _Summary(counts: dashboard.counts),
                    const SizedBox(height: 28),
                    _Group(
                      section: ProviderDashboardSection.paid,
                      group: dashboard.paid,
                      storeId: dashboard.selectedStoreId,
                    ),
                    _Group(
                      section: ProviderDashboardSection.awaitingPayment,
                      group: dashboard.awaitingPayment,
                      storeId: dashboard.selectedStoreId,
                    ),
                    _Group(
                      section: ProviderDashboardSection.pendingDirect,
                      group: dashboard.pendingDirect,
                      storeId: dashboard.selectedStoreId,
                    ),
                    _Sales(dashboard: dashboard),
                    const SizedBox(height: 28),
                    OutlinedButton.icon(
                      key: const Key('dashboard-order-history'),
                      onPressed: () => ProviderDashboardActivityRoute(
                        section: ProviderDashboardSection.recent.apiValue,
                        storeId: dashboard.selectedStoreId,
                      ).push<void>(context),
                      icon: const Icon(Icons.history_rounded),
                      label: Text(
                        context.tr('provider_dashboard.view_history'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr(
                        'provider_dashboard.updated',
                        args: [
                          DateFormat.Hm(
                            context.locale.toLanguageTag(),
                          ).format(dashboard.generatedAt.toLocal()),
                        ],
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              Text(
                context.tr('provider_portal.shortcuts'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ProviderNavigationTile(
                key: const Key('provider-shortcut-offers'),
                titleKey: 'provider_portal.offers',
                icon: Icons.local_offer_outlined,
                onTap: () =>
                    const ProviderOrdersRoute(section: 'offers').go(context),
              ),
              ProviderNavigationTile(
                key: const Key('provider-shortcut-stores'),
                titleKey: 'provider_stores.title',
                icon: Icons.storefront_outlined,
                onTap: () => const ProviderStoresRoute().go(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.counts});
  final ProviderDashboardCounts counts;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final twoColumns =
          constraints.maxWidth >= 320 &&
          MediaQuery.textScalerOf(context).scale(1) < 1.5;
      final width = twoColumns
          ? (constraints.maxWidth - 12) / 2
          : constraints.maxWidth;
      final metrics = [
        (
          'pending_direct_count',
          counts.pendingDirectRequests,
          Icons.receipt_long_outlined,
          OctoGearColors.warning,
        ),
        (
          'pending_offers_count',
          counts.pendingOffers,
          Icons.local_offer_outlined,
          OctoGearColors.structuralGray,
        ),
        (
          'accepted_offers_count',
          counts.acceptedOffers,
          Icons.task_alt_rounded,
          OctoGearColors.information,
        ),
        (
          'paid_count',
          counts.paidOrders,
          Icons.payments_outlined,
          OctoGearColors.success,
        ),
      ];
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final (label, count, icon, color) in metrics)
            SizedBox(
              width: width,
              child: OctoGearSurfaceCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: color, size: 24),
                    const SizedBox(height: 12),
                    Text(
                      NumberFormat.decimalPattern(
                        context.locale.toLanguageTag(),
                      ).format(count),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('provider_dashboard.$label'),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _Group extends StatelessWidget {
  const _Group({
    required this.section,
    required this.group,
    required this.storeId,
  });
  final ProviderDashboardSection section;
  final ProviderDashboardOrderGroup group;
  final int? storeId;
  @override
  Widget build(BuildContext context) {
    final name = dashboardSectionKey(section);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Semantics(
              header: true,
              child: Text(
                context.tr('provider_dashboard.$name'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (group.total > 0)
              TextButton(
                key: ValueKey('dashboard-view-$name'),
                onPressed: () => ProviderDashboardActivityRoute(
                  section: section.apiValue,
                  storeId: storeId,
                ).push<void>(context),
                child: Text(
                  context.tr(
                    'provider_dashboard.view_all',
                    args: [
                      NumberFormat.decimalPattern(
                        context.locale.toLanguageTag(),
                      ).format(group.total),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(context.tr('provider_dashboard.${name}_hint')),
        const SizedBox(height: 16),
        if (group.items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              context.tr('provider_dashboard.${name}_empty'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          for (final order in group.items)
            DashboardOrderCard(
              key: ValueKey('dashboard-$name-${order.id}'),
              order: order,
            ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _Sales extends ConsumerWidget {
  const _Sales({required this.dashboard});
  final ProviderDashboard dashboard;
  @override
  Widget build(BuildContext context, WidgetRef ref) => OctoGearSurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr('provider_dashboard.sales'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<ProviderDashboardPeriod>(
          key: ValueKey('dashboard-period-${dashboard.period.name}'),
          initialValue: dashboard.period,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: context.tr('provider_dashboard.period'),
          ),
          items: [
            for (final period in ProviderDashboardPeriod.values)
              DropdownMenuItem(
                value: period,
                child: Text(
                  context.tr('provider_dashboard.period_${period.name}'),
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              ref
                  .read(providerDashboardFilterProvider.notifier)
                  .selectPeriod(value);
            }
          },
        ),
        const SizedBox(height: 20),
        Text(
          offerMoney(context, dashboard.sales.amount),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          context.tr(
            'provider_dashboard.payment_count',
            args: [
              NumberFormat.decimalPattern(
                context.locale.toLanguageTag(),
              ).format(dashboard.sales.count),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr(
            'provider_dashboard.sales_hint',
            namedArgs: {'timezone': dashboard.sales.timezone},
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}
