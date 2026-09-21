import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahala/core/routing/app_routes.dart';
import 'package:sahala/core/service/app_logger.dart';
import 'package:sahala/core/widgets/app_scaffold.dart';
import 'package:sahala/core/widgets/countdown_timer.dart';
import 'package:sahala/core/widgets/loading_outlined_button.dart';
import 'package:sahala/core/widgets/loading_text_button.dart';
import 'package:sahala/core/widgets/otp_input.dart';
import 'package:sahala/features/authentication/data/models/otp_verify_request_model.dart';
import 'package:sahala/features/authentication/presentation/providers/otp_provider.dart';
import 'package:toastify_flutter/toastify_flutter.dart';

class OTPScreen extends ConsumerStatefulWidget {
  const OTPScreen({super.key});

  @override
  ConsumerState<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends ConsumerState<OTPScreen> {
  final _otpInputKey = GlobalKey<OtpInputState>();

  @override
  Widget build(BuildContext context) {
    final otpNotifier = ref.read(otpProvider.notifier);
    final otpState = ref.watch(otpProvider);

    ref.listen(otpProvider, (previous, next) {
      if (next.isError && previous?.isError != true) {
        _otpInputKey.currentState?.reset();
        ToastifyFlutter.error(
          context,
          message: 'Invalid OTP',
          duration: 3,
          position: ToastPosition.top,
          style: ToastStyle.flat,
          onClose: true,
        );
      }

      if (next.isSuccess && previous?.isSuccess != true) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
      }
    });

    final arguments = ModalRoute.of(context)?.settings.arguments;
    unawaited(AppLogger.log('OTP arguments: $arguments', category: 'OTP'));
    final phoneNumber =
        ModalRoute.of(context)!.settings.arguments as String? ?? "";
    return AppScaffold(
      showAppBar: true,
      title: "Verification",
      body: Padding(
        padding: EdgeInsets.all(24.0),

        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(30),
            width: double.infinity,
            // height: 330,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.all(Radius.circular(30.0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 10,
              children: [
                const Text(
                  'Verify Mobile Number',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Row(
                  spacing: 5,
                  children: [
                    Text(
                      'A 4-digit code sent to',
                      style: TextStyle(color: const Color(0xFFDEDEDE)),
                    ),
                    Text(
                      '+966 $phoneNumber',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),

                const Text('Enter code here', style: TextStyle(fontSize: 16)),

                OtpInput(
                  key: _otpInputKey,
                  length: 4,
                  onCompleted: (value) {
                    final body = OtpVerifyRequestModel(
                      otp: value,
                      mobileNumber: phoneNumber,
                    );

                    otpNotifier.otpVerify(body);
                    // Not logging `value` itself - it's the OTP code, and
                    // AppLogger.log only redacts Map/Iterable structures by
                    // key, not plain strings (see PROJECT_DOCUMENTATION.md's
                    // AppLogger section on what not to log).
                    unawaited(
                      AppLogger.log(
                        'OTP entry completed (${value.length} digits)',
                        category: 'OTP',
                      ),
                    );
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 5,
                  children: [
                    Text(
                      "Haven’t received?",
                      style: TextStyle(color: const Color(0xFFDEDEDE)),
                    ),
                    if (otpState.showCounter)
                      CountdownTimer(
                        duration: const Duration(seconds: 120),
                        onFinished: () {
                          ref.read(otpProvider.notifier).onCountdownFinished();
                        },
                      )
                    else
                      LoadingTextButton(
                        label: 'Resend',
                        onPressed: () {
                          ref.read(otpProvider.notifier).resendOTP(phoneNumber);
                        },
                        isLoading: otpState.isResending,
                      ),
                    // TextButton(
                    //   onPressed: () {
                    //     ref.read(otpProvider.notifier).resendOTP(phoneNumber);
                    //   },
                    //   child: Text('Resend'),
                    // ),
                  ],
                ),
                LoadingOutlinedButton(
                  label: 'Continue',
                  onPressed: () {},
                  isLoading: otpState.isLoading,
                ),
                // OutlinedButton(onPressed: () {}, child: Text("Continue")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
