import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/api/api_failure.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../controllers/general_request_providers.dart';
import 'general_request_feedback.dart';

/// Shared page frame: heading, progress, feedback and next/cancel actions.
/// Draft ownership, validation, navigation and network work stay in the screen.
class GeneralRequestFlowLayout extends StatelessWidget {
  const GeneralRequestFlowLayout({
    required this.state,
    required this.step,
    required this.picking,
    required this.scrollController,
    required this.content,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
    required this.onCancel,
    super.key,
  });
  final GeneralRequestState state;
  final int step;
  final bool picking;
  final ScrollController scrollController;
  final Widget content;
  final VoidCallback onBack, onNext, onSubmit, onCancel;
  @override
  Widget build(BuildContext context) {
    String tr(String key) => context.tr('general_request.$key');
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 28),
          children: [
            Row(
              children: [
                IconButton(
                  key: const Key('general-back'),
                  onPressed: state.submitting || picking ? null : onBack,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  icon: const BackButtonIcon(),
                ),
                Expanded(
                  child: Text(
                    tr('title'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const AppLanguageToggleButton(compact: true),
              ],
            ),
            const SizedBox(height: 16),
            if (state.orderId != null)
              content
            else ...[
              Semantics(
                header: true,
                child: Text(
                  context.tr(
                    'general_request.step',
                    namedArgs: {
                      'number': '${step + 1}',
                      'name': tr(['vehicle', 'part', 'review'][step]),
                    },
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (step + 1) / 3,
                  minHeight: 4,
                  backgroundColor: OctoGearColors.border,
                  color: OctoGearColors.navy,
                  semanticsLabel: tr(['vehicle', 'part', 'review'][step]),
                ),
              ),
              const SizedBox(height: 24),
              content,
              if (state.error != null) ...[
                GeneralRequestFeedback(
                  message: state.error!.statusCode == 409
                      ? context.tr('part_request.conflict')
                      : state.retryCommand != null
                      ? context.tr('part_request.uncertain')
                      : context.tr(switch (state.error!.type) {
                          ApiFailureType.validation =>
                            'part_request.validation_error',
                          ApiFailureType.rateLimited =>
                            'part_request.rate_limit',
                          ApiFailureType.forbidden ||
                          ApiFailureType.unauthorized =>
                            'part_request.access_error',
                          _ => 'part_request.send_error',
                        }),
                ),
                for (final errors in state.error!.fieldErrors.values)
                  for (final message in errors)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        message,
                        style: const TextStyle(color: OctoGearColors.error),
                      ),
                    ),
              ],
              const SizedBox(height: 24),
              if (step == 2) ...[
                Text(
                  tr('no_charge'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
              ],
              FilledButton.icon(
                key: const Key('general-next'),
                onPressed:
                    state.submitting ||
                        picking ||
                        state.error?.statusCode == 409
                    ? null
                    : step < 2
                    ? onNext
                    : onSubmit,
                icon: state.submitting || picking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        step < 2 ? Icons.arrow_forward : Icons.send_outlined,
                      ),
                label: Text(
                  step < 2
                      ? tr(step == 0 ? 'continue_part' : 'continue_review')
                      : context.tr(
                          state.submitting
                              ? 'part_request.sending'
                              : state.retryCommand != null
                              ? 'part_request.retry'
                              : 'general_request.send',
                        ),
                ),
              ),
              TextButton(
                onPressed: state.submitting || picking ? null : onCancel,
                child: Text(tr('cancel')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
