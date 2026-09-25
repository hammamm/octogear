import 'package:flutter/material.dart';

import '../design_system/octogear_theme.dart';

/// Shared white content surface for forms, status states, and temporary shells.
class OctoGearSurfaceCard extends StatelessWidget {
  const OctoGearSurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: semanticLabel != null,
      label: semanticLabel,
      child: Card(
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

enum OctoGearFeedbackTone { error, success, information }

/// A concise inline status message that keeps validation and request feedback
/// readable without changing feature state or error mapping.
class OctoGearFeedbackBanner extends StatelessWidget {
  const OctoGearFeedbackBanner({
    required this.message,
    required this.tone,
    super.key,
  });

  final String message;
  final OctoGearFeedbackTone tone;

  @override
  Widget build(BuildContext context) {
    final (color, background, icon) = switch (tone) {
      OctoGearFeedbackTone.error => (
        OctoGearColors.error,
        const Color(0xFFFFF0EF),
        Icons.error_outline_rounded,
      ),
      OctoGearFeedbackTone.success => (
        OctoGearColors.success,
        const Color(0xFFEDF9F2),
        Icons.check_circle_outline_rounded,
      ),
      OctoGearFeedbackTone.information => (
        OctoGearColors.information,
        const Color(0xFFEFF6FF),
        Icons.info_outline_rounded,
      ),
    };

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsetsDirectional.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(OctoGearRadii.small),
          border: Border.all(color: color.withValues(alpha: .24)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: OctoGearSpacing.small),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
