import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../provider_orders/presentation/screens/provider_general_requests_panel.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../widgets/provider_page.dart';

/// General Requests is live; the other provider order workflows are separate slices.
class ProviderOrdersScreen extends StatelessWidget {
  const ProviderOrdersScreen({super.key});

  static const sections = ['general', 'direct', 'offers', 'paid'];

  @override
  Widget build(BuildContext context) {
    final tabHeight = 48 * MediaQuery.textScalerOf(context).scale(1);
    return DefaultTabController(
      length: sections.length,
      child: Column(
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
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final section in sections)
                Tab(
                  key: ValueKey('provider-orders-$section'),
                  height: tabHeight,
                  text: context.tr('provider_portal.$section'),
                ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                for (final section in sections)
                  if (section == 'general')
                    const ProviderGeneralRequestsPanel()
                  else
                    ListView(
                      key: PageStorageKey('provider-orders-$section'),
                      padding: const EdgeInsets.all(20),
                      children: [
                        ProviderSectionPlaceholder(
                          icon: Icons.receipt_long_outlined,
                          descriptionKey:
                              'provider_portal.${section}_placeholder',
                        ),
                      ],
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
