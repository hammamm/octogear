import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../controllers/offer_action_controller.dart';
import 'order_widgets.dart';

class OfferActionFeedback extends StatelessWidget {
  const OfferActionFeedback({
    required this.state,
    required this.onRefresh,
    super.key,
  });
  final OfferActionState state;
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) {
    if (state.error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OctoGearFeedbackBanner(
            message: state.error!.statusCode == 409
                ? context.tr('offer_flow.changed')
                : state.needsRefresh
                ? context.tr('offer_flow.check_result')
                : ordersErrorMessage(context, state.error!),
            tone: OctoGearFeedbackTone.error,
          ),
          for (final errors in state.error!.fieldErrors.values)
            for (final message in errors)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(message),
              ),
          if (state.needsRefresh)
            TextButton.icon(
              onPressed: state.busy ? null : onRefresh,
              icon: const Icon(Icons.refresh),
              label: Text(context.tr('offer_flow.refresh_status')),
            ),
        ],
      ),
    );
  }
}
