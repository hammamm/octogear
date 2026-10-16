import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/routing/app_route_paths.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../../provider_orders/domain/entities/provider_managed_order.dart';
import '../../../provider_orders/presentation/screens/provider_general_requests_panel.dart';
import '../../../provider_orders/presentation/screens/provider_managed_orders_panel.dart';
import '../../../provider_orders/presentation/screens/provider_offers_panel.dart';

/// Separate discovery, direct requests, offers and paid fulfillment workflows.
class ProviderOrdersScreen extends StatefulWidget {
  const ProviderOrdersScreen({this.initialSection = 'general', super.key});
  final String initialSection;

  static const sections = ['general', 'direct', 'offers', 'paid'];

  @override
  State<ProviderOrdersScreen> createState() => _ProviderOrdersScreenState();
}

class _ProviderOrdersScreenState extends State<ProviderOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  int _indexFor(String section) {
    final index = ProviderOrdersScreen.sections.indexOf(section);
    return index < 0 ? 0 : index;
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: ProviderOrdersScreen.sections.length,
      initialIndex: _indexFor(widget.initialSection),
      vsync: this,
    )..addListener(_sectionChanged);
  }

  @override
  void didUpdateWidget(covariant ProviderOrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSection != widget.initialSection) {
      _tabs.animateTo(_indexFor(widget.initialSection));
    }
  }

  void _sectionChanged() {
    if (_tabs.indexIsChanging) return;
    final section = ProviderOrdersScreen.sections[_tabs.index];
    final router = GoRouter.of(context);
    final uri = router.routeInformationProvider.value.uri;
    // Keep taps and swipes in the URL so dashboard shortcuts can select a
    // different section, while bottom navigation restores the last open tab.
    // A hidden branch must never navigate away from another active page.
    if (uri.path == AppRoutePath.providerOrders &&
        (uri.queryParameters['section'] ?? 'general') != section) {
      ProviderOrdersRoute(section: section).go(context);
    }
  }

  @override
  void dispose() {
    _tabs.removeListener(_sectionChanged);
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabHeight = 48 * MediaQuery.textScalerOf(context).scale(1);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    context.tr('provider_portal.orders'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
              const AppLanguageToggleButton(compact: true),
            ],
          ),
        ),
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            for (final section in ProviderOrdersScreen.sections)
              Tab(
                key: ValueKey('provider-orders-$section'),
                height: tabHeight,
                text: context.tr('provider_portal.$section'),
              ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              for (final section in ProviderOrdersScreen.sections)
                if (section == 'general')
                  const ProviderGeneralRequestsPanel()
                else if (section == 'offers')
                  const ProviderOffersPanel()
                else
                  ProviderManagedOrdersPanel(
                    kind: section == 'direct'
                        ? ProviderOrderKind.direct
                        : ProviderOrderKind.paid,
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
