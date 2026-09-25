import 'dart:async';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/routing/app_routes.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/design_system/octogear_theme.dart';
import '../../../../core/widgets/app_language_toggle_button.dart';
import '../../../../core/widgets/octogear_brand_header.dart';
import '../../../../core/widgets/octogear_page_scaffold.dart';
import '../../../../core/widgets/octogear_surface_card.dart';
import '../../domain/entities/saudi_mobile_number.dart';
import '../controllers/phone_sign_in_controller.dart';
import '../widgets/authentication_failure_text.dart';

class PhoneSignInScreen extends ConsumerStatefulWidget {
  const PhoneSignInScreen({super.key});

  @override
  ConsumerState<PhoneSignInScreen> createState() => _PhoneSignInScreenState();
}

class _PhoneSignInScreenState extends ConsumerState<PhoneSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  SaudiMobileNumber? get _mobile =>
      SaudiMobileNumber.tryParse(_phoneController.text);

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onPhoneChanged(String value) {
    ref.read(phoneSignInControllerProvider.notifier).clearError();
    setState(() {});
  }

  void _sendOtp() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final mobile = _mobile;
    if (mobile == null) return;
    unawaited(ref.read(phoneSignInControllerProvider.notifier).sendOtp(mobile));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PhoneSignInState>(phoneSignInControllerProvider, (
      previous,
      next,
    ) {
      if (next.successfulSubmissionCount >
              (previous?.successfulSubmissionCount ?? 0) &&
          mounted) {
        unawaited(const OtpVerificationRoute().push(context));
      }
    });

    final request = ref.watch(phoneSignInControllerProvider);
    final error = request.error;
    final canSubmit = _mobile != null && !request.isSubmitting;
    final isRetryableNetworkFailure =
        error is ApiFailure &&
        (error.type == ApiFailureType.noConnection ||
            error.type == ApiFailureType.timeout);

    return OctoGearPageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AppLanguageToggleButton(),
          ),
          const SizedBox(height: OctoGearSpacing.large),
          const OctoGearBrandHeader(),
          const SizedBox(height: OctoGearSpacing.xxLarge),
          OctoGearSurfaceCard(
            semanticLabel: context.tr('auth.welcome'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr('auth.welcome'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: OctoGearSpacing.xSmall),
                Text(
                  context.tr('auth.description'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: OctoGearColors.structuralGray,
                  ),
                ),
                const SizedBox(height: OctoGearSpacing.xLarge),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _phoneController,
                    readOnly: request.isSubmitting,
                    autofocus: true,
                    textDirection: ui.TextDirection.ltr,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(9),
                    ],
                    decoration: InputDecoration(
                      labelText: context.tr('auth.phone_label'),
                      hintText: context.tr('auth.phone_hint'),
                      prefixIcon: const Icon(Icons.phone_android_rounded),
                      prefixText: '+966  ',
                    ),
                    validator: (value) =>
                        SaudiMobileNumber.tryParse(value ?? '') == null
                        ? context.tr('auth.phone_invalid')
                        : null,
                    onChanged: _onPhoneChanged,
                    onFieldSubmitted: (_) => _sendOtp(),
                  ),
                ),
                const SizedBox(height: OctoGearSpacing.small),
                Text(
                  context.tr('auth.phone_note'),
                  style: Theme.of(context).textTheme.bodyMedium,
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
                  onPressed: canSubmit ? _sendOtp : null,
                  child: request.isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.tr(
                                isRetryableNetworkFailure
                                    ? 'common.retry'
                                    : 'auth.continue',
                              ),
                            ),
                            const SizedBox(width: OctoGearSpacing.xSmall),
                            const Icon(Icons.arrow_forward_rounded),
                          ],
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
