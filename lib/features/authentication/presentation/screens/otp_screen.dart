import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahala/core/widgets/app_background.dart';
import 'package:sahala/core/widgets/app_scaffold.dart';
import 'package:sahala/core/widgets/countdown_timer.dart';
import 'package:sahala/core/widgets/otp_input.dart';
import 'package:sahala/features/authentication/data/models/otp_verify_request_model.dart';
import 'package:sahala/features/authentication/presentation/providers/otp_provider.dart';

class OTPScreen extends ConsumerStatefulWidget {
  const OTPScreen({super.key});

  @override
  ConsumerState<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends ConsumerState<OTPScreen> {
  @override
  Widget build(BuildContext context) {
    final otpNotifier = ref.read(otpProvider.notifier);
    final otpState = ref.watch(otpProvider);
    final arguments = ModalRoute.of(context)?.settings.arguments;
    debugPrint('OTP arguments: $arguments');
    final phoneNumber =
        ModalRoute.of(context)!.settings.arguments as String? ?? "";
    return AppScaffold(
      showAppBar: true,
      title: "Verification",
      body: Padding(
        padding: EdgeInsets.all(24.0),

        child: Container(
          padding: EdgeInsets.all(30),
          width: double.infinity,
          height: 330,
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
                length: 4,
                onCompleted: (value) {
                  final body = OtpVerifyRequestModel(
                    otp: value,
                    mobileNumber: phoneNumber,
                  );

                  otpNotifier.otpVerify(body);
                  debugPrint(value);
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
                  CountdownTimer(duration: const Duration(seconds: 36)),
                ],
              ),
              OutlinedButton(onPressed: () {}, child: Text("Continue")),
            ],
          ),
        ),
      ),
    );
  }
}
