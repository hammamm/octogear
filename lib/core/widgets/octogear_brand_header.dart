import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../design_system/octogear_theme.dart';

/// Shared OctoGear lockup using the approved full-color original mark.
///
/// The source asset is the high-resolution mark extracted from the approved
/// brand guide. Keep its proportions and colors intact; only its displayed size
/// changes between compact and full headers.
class OctoGearBrandHeader extends StatelessWidget {
  const OctoGearBrandHeader({
    this.compact = false,
    this.showTagline = true,
    super.key,
  });

  final bool compact;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final markSize = compact ? 52.0 : 84.0;
    final decodedMarkSize = (markSize * MediaQuery.devicePixelRatioOf(context))
        .round();

    return Semantics(
      label: context.tr('app.name'),
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(
                compact ? OctoGearRadii.small : OctoGearRadii.medium,
              ),
              child: Image.asset(
                'assets/icons/app_icon.png',
                width: markSize,
                height: markSize,
                cacheWidth: decodedMarkSize,
                cacheHeight: decodedMarkSize,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
            SizedBox(height: compact ? 10 : 14),
            Text(
              'OCTOGEAR',
              textDirection: ui.TextDirection.ltr,
              style: TextStyle(
                color: OctoGearColors.navy,
                fontFamily: 'Arial',
                fontSize: compact ? 20 : 28,
                fontWeight: FontWeight.w800,
                height: 1,
                letterSpacing: compact ? 1.1 : 1.6,
              ),
            ),
            SizedBox(height: compact ? 7 : 10),
            Container(
              height: 3,
              width: compact ? 36 : 48,
              decoration: BoxDecoration(
                color: OctoGearColors.yellow,
                borderRadius: BorderRadius.circular(OctoGearRadii.pill),
              ),
            ),
            if (showTagline) ...[
              SizedBox(height: compact ? 4 : 8),
              Text(
                context.tr('app.tagline'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: OctoGearColors.structuralGray,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
