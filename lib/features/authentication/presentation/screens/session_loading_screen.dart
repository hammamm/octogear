import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/octogear_brand_header.dart';
import '../../../../core/widgets/octogear_page_scaffold.dart';
import '../../../../core/widgets/octogear_surface_card.dart';

class SessionLoadingScreen extends StatelessWidget {
  const SessionLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OctoGearPageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: OctoGearSpacing.xLarge),
          const OctoGearBrandHeader(),
          const SizedBox(height: 72),
          OctoGearSurfaceCard(
            semanticLabel: context.tr('session.loading'),
            child: Column(
              children: [
                const SizedBox(
                  height: 48,
                  width: 48,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: OctoGearSpacing.large),
                Text(
                  context.tr('session.loading'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: OctoGearSpacing.xSmall),
                Text(
                  context.tr('session.loading_description'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
