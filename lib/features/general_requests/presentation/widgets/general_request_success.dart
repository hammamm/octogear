import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/octogear_surface_card.dart';

class GeneralRequestSuccess extends StatelessWidget {
  const GeneralRequestSuccess({
    required this.orderId,
    required this.onViewRequest,
    required this.onDone,
    super.key,
  });
  final int orderId;
  final VoidCallback onViewRequest, onDone;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: OctoGearSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: OctoGearColors.success,
            size: 56,
          ),
          const SizedBox(height: 20),
          Text(
            context.tr('part_request.success_title'),
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('general_request.success_hint'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('part_request.reference', args: ['$orderId']),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onViewRequest,
            child: Text(context.tr('orders.view_request')),
          ),
          TextButton(
            onPressed: onDone,
            child: Text(context.tr('part_request.done')),
          ),
        ],
      ),
    ),
  );
}
