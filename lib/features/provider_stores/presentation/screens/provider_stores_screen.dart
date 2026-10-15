import 'package:flutter/material.dart';

import '../../../provider_portal/presentation/widgets/provider_page.dart';
import '../widgets/provider_stores_panel.dart';

class ProviderStoresScreen extends StatelessWidget {
  const ProviderStoresScreen({super.key});

  @override
  Widget build(BuildContext context) => const ProviderPage(
    titleKey: 'provider_portal.store_details',
    showBack: true,
    children: [ProviderStoresPanel()],
  );
}
