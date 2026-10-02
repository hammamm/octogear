import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../../../core/widgets/octogear_surface_card.dart';

/// Intentional release placeholder. No messaging providers or API calls.
class CustomerChatsScreen extends StatelessWidget {
  const CustomerChatsScreen({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    key: const PageStorageKey('customer-tab-chats'),
    padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              context.tr('customer_chats.tab'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const AppLanguageToggleButton(compact: true),
        ],
      ),
      const SizedBox(height: 32),
      OctoGearSurfaceCard(
        child: Column(
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: OctoGearColors.yellowSoft,
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 32,
                color: OctoGearColors.navy,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('customer_chats.coming_soon'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('customer_chats.description'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ],
  );
}
