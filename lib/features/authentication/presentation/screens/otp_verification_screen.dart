import 'dart:async';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../../../core/widgets/octogear_brand_header.dart';
import '../../../../core/widgets/octogear_page_scaffold.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/otp_verification_outcome.dart';
import '../controllers/authentication_flow_controller.dart';
import '../controllers/otp_resend_controller.dart';
import '../controllers/otp_verification_controller.dart';
import '../controllers/session_controller.dart';
import '../widgets/authentication_failure_text.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final mobile = ref.read(authenticationFlowProvider).mobile;
    if (mobile == null) return;

    await ref
        .read(otpVerificationControllerProvider.notifier)
        .verify(mobile: mobile, otp: _otpController.text);
  }

  Future<void> _resend() async {
    final mobile = ref.read(authenticationFlowProvider).mobile;
    if (mobile == null) return;

    await ref.read(otpResendControllerProvider.notifier).resend(mobile);
  }

  Future<void> _handleOutcome(OtpVerificationOutcome outcome) async {
    switch (outcome) {
      case ExistingAccountVerified():
        ref.read(authenticationFlowProvider.notifier).clear();
        await ref.read(sessionControllerProvider.notifier).retry();
        if (!mounted) return;
        const SessionLoadingRoute().go(context);
      case RegistrationRequired(:final temporaryRegistrationToken):
        ref
            .read(authenticationFlowProvider.notifier)
            .requireRegistration(temporaryRegistrationToken);
        if (!mounted) return;
        unawaited(const RegistrationRoute().push(context));
    }
    ref.read(otpVerificationControllerProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<OtpVerificationOutcome?>>(
      otpVerificationControllerProvider,
      (previous, next) {
        final outcome = next.asData?.value;
        if (previous?.isLoading == true && outcome != null && mounted) {
          unawaited(_handleOutcome(outcome));
        }
      },
    );

    final mobile = ref.watch(authenticationFlowProvider).mobile;
    final verification = ref.watch(otpVerificationControllerProvider);
    final resend = ref.watch(otpResendControllerProvider);
    final canSubmit =
        _otpController.text.length == 4 && !verification.isLoading;
    final error = verification.asError?.error;

    return OctoGearPageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => context.pop(),
                icon: const BackButtonIcon(),
              ),
              const AppLanguageToggleButton(compact: true),
            ],
          ),
          const SizedBox(height: OctoGearSpacing.medium),
          const OctoGearBrandHeader(compact: true),
          const SizedBox(height: OctoGearSpacing.xLarge),
          OctoGearSurfaceCard(
            semanticLabel: context.tr('auth.otp_title'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr('auth.otp_title'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: OctoGearSpacing.xSmall),
                Text(
                  context.tr('auth.otp_description'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: OctoGearColors.structuralGray,
                  ),
                ),
                const SizedBox(height: OctoGearSpacing.medium),
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: OctoGearSpacing.medium,
                    vertical: OctoGearSpacing.small,
                  ),
                  decoration: BoxDecoration(
                    color: OctoGearColors.yellowSoft,
                    borderRadius: BorderRadius.circular(OctoGearRadii.small),
                  ),
                  child: Text(
                    mobile?.displayValue ?? '',
                    textAlign: TextAlign.center,
                    textDirection: ui.TextDirection.ltr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: OctoGearColors.navy,
                    ),
                  ),
                ),
                const SizedBox(height: OctoGearSpacing.xLarge),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _otpController,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    textDirection: ui.TextDirection.ltr,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: InputDecoration(
                      labelText: context.tr('auth.otp_label'),
                      hintText: context.tr('auth.otp_hint'),
                      counterText: '',
                    ),
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(letterSpacing: 10),
                    validator: (value) => value?.length != 4
                        ? context.tr('auth.otp_invalid')
                        : null,
                    onChanged: (_) => setState(() {}),
                    onFieldSubmitted: (_) => unawaited(_verify()),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: OctoGearSpacing.medium),
                  OctoGearFeedbackBanner(
                    message: authenticationFailureText(context, error),
                    tone: OctoGearFeedbackTone.error,
                  ),
                ],
                const SizedBox(height: OctoGearSpacing.large),
                FilledButton(
                  onPressed: canSubmit ? _verify : null,
                  child: verification.isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(context.tr('auth.verify')),
                ),
                const SizedBox(height: OctoGearSpacing.small),
                TextButton(
                  onPressed: resend.isSubmitting ? null : _resend,
                  child: resend.isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.tr('auth.resend_otp')),
                ),
                if (resend.error != null)
                  OctoGearFeedbackBanner(
                    message: authenticationFailureText(context, resend.error),
                    tone: OctoGearFeedbackTone.error,
                  ),
                if (resend.successfulSubmissionCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: OctoGearSpacing.small),
                    child: OctoGearFeedbackBanner(
                      message: context.tr('auth.otp_resent'),
                      tone: OctoGearFeedbackTone.success,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
