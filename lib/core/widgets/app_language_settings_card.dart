import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'app_language_toggle_button.dart';
import 'octogear_surface_card.dart';

class AppLanguageSettingsCard extends StatelessWidget {
  const AppLanguageSettingsCard({super.key});

  @override
  Widget build(BuildContext context) => OctoGearSurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr('app_settings.language'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(context.tr('app_settings.language_description')),
        const SizedBox(height: 16),
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppLanguageToggleButton(),
        ),
      ],
    ),
  );
}
