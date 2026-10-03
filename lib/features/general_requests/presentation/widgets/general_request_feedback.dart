import 'package:flutter/material.dart';

import '../../../../core/widgets/octogear_surface_card.dart';

/// Shared inline feedback for the request steps and submission errors.
class GeneralRequestFeedback extends StatelessWidget {
  const GeneralRequestFeedback({required this.message, super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Semantics(
      liveRegion: true,
      child: OctoGearFeedbackBanner(
        message: message,
        tone: OctoGearFeedbackTone.error,
      ),
    ),
  );
}
