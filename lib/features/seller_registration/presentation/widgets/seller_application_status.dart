import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/seller_application.dart';

class SellerApplicationStatusView extends StatelessWidget {
  const SellerApplicationStatusView({
    required this.application,
    required this.onRefresh,
    required this.onCorrect,
    super.key,
  });
  final SellerApplication application;
  final VoidCallback? onRefresh, onCorrect;
  @override
  Widget build(BuildContext context) {
    final status = application.status;
    final key = status.name;
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OctoGearSurfaceCard(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: OctoGearColors.yellowSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  switch (status) {
                    SellerApplicationStatus.pending =>
                      Icons.hourglass_top_rounded,
                    SellerApplicationStatus.accepted => Icons.verified_outlined,
                    SellerApplicationStatus.rejected => Icons.edit_note_rounded,
                  },
                  size: 40,
                  color: OctoGearColors.navy,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.tr('seller.status_$key'),
                textAlign: TextAlign.center,
                style: theme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('seller.status_${key}_body'),
                textAlign: TextAlign.center,
              ),
              if (status == SellerApplicationStatus.rejected &&
                  application.rejectionReason?.isNotEmpty == true) ...[
                const SizedBox(height: 20),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    application.rejectionReason!,
                    style: theme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        OctoGearSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(application.name, style: theme.titleLarge),
              const SizedBox(height: 8),
              Text(application.city.name),
              const SizedBox(height: 8),
              Text(application.mobile, textDirection: TextDirection.ltr),
              const SizedBox(height: 12),
              Text(
                context.tr(
                  'seller.reference',
                  args: [application.id.toString()],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (status == SellerApplicationStatus.rejected) ...[
          FilledButton.icon(
            key: const Key('seller-correct'),
            onPressed: onCorrect,
            icon: const Icon(Icons.edit_outlined),
            label: Text(context.tr('seller.correct')),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(context.tr('seller.check_status')),
        ),
      ],
    );
  }
}
