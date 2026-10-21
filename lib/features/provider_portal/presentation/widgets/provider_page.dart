import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/octogear_theme.dart';
import 'package:octogear/features/support_chat/presentation/widgets/support_entry.dart';
import '../../../../core/widgets/octogear_surface_card.dart';

/// Scrollable content inside the provider shell; the shell owns safe areas.
class ProviderPage extends StatelessWidget {
  const ProviderPage({
    required this.titleKey,
    required this.children,
    this.showBack = false,
    super.key,
  });

  final String titleKey;
  final List<Widget> children;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          key: PageStorageKey(titleKey),
          padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 32),
          children: [
            Row(
              children: [
                if (showBack) const BackButton(),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      context.tr(titleKey),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const SupportButton(),
              ],
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

class ProviderSectionPlaceholder extends StatelessWidget {
  const ProviderSectionPlaceholder({
    required this.icon,
    required this.descriptionKey,
    super.key,
  });
  final IconData icon;
  final String descriptionKey;

  @override
  Widget build(BuildContext context) => OctoGearSurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Icon(icon, size: 36, color: OctoGearColors.navy),
        ),
        const SizedBox(height: 16),
        Text(
          context.tr('provider_portal.coming_soon'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(context.tr(descriptionKey)),
      ],
    ),
  );
}

class ProviderNavigationTile extends StatelessWidget {
  const ProviderNavigationTile({
    required this.titleKey,
    required this.icon,
    required this.onTap,
    super.key,
  });
  final String titleKey;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
        leading: Icon(icon),
        title: Text(context.tr(titleKey)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
        onTap: onTap,
      ),
    ),
  );
}
