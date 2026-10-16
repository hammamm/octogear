import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../app/routing/app_routes.dart';

import '../../../provider_portal/presentation/widgets/provider_page.dart';
import '../widgets/provider_stores_panel.dart';

class ProviderStoresScreen extends StatelessWidget {
  const ProviderStoresScreen({super.key});

  @override
  Widget build(BuildContext context) => ProviderPage(
    titleKey: 'provider_portal.store_details',
    showBack: true,
    children: [
      FilledButton.icon(
        key: const Key('store-add'),
        onPressed: () => const ProviderStoreAddRoute().push<void>(context),
        icon: const Icon(Icons.add_business_outlined),
        label: Text(context.tr('store_management.add')),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        key: const Key('store-applications'),
        onPressed: () =>
            const ProviderStoreApplicationsRoute().push<void>(context),
        icon: const Icon(Icons.fact_check_outlined),
        label: Text(context.tr('store_management.applications')),
      ),
      const SizedBox(height: 24),
      const ProviderStoresPanel(),
    ],
  );
}
