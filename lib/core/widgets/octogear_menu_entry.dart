import 'package:flutter/material.dart';

import '../design_system/octogear_theme.dart';
import 'octogear_surface_card.dart';

/// Common menu appearance; feature widgets supply content and navigation.
class OctoGearMenuEntry extends StatelessWidget {
  const OctoGearMenuEntry({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final Widget leading;
  final String title, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OctoGearSurfaceCard(
    padding: const EdgeInsets.all(20),
    onTap: onTap,
    child: Row(
      children: [
        IconTheme.merge(
          data: const IconThemeData(color: OctoGearColors.navy, size: 26),
          child: leading,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(subtitle),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.arrow_forward_rounded),
      ],
    ),
  );
}
