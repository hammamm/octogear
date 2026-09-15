import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahala/core/service/app_logger.dart';
import 'package:sahala/dependency_injection.dart';
import 'package:sahala/features/authentication/data/models/otp_verify_request_model.dart';
import 'package:sahala/features/authentication/domain/use_cases/otp_use_case.dart';

final otpProvider = NotifierProvider<OtpNotifier, OtpState>(OtpNotifier.new);

class OtpState {}

class OtpNotifier extends Notifier<OtpState> {
  late final OtpUseCase _otpUseCase;
  @override
  OtpState build() {
    _otpUseCase = sl<OtpUseCase>();
    return OtpState();
  }

  Future<void> otpVerify(OtpVerifyRequestModel body) async {
    try {
      await _otpUseCase(body);
      await AppLogger.log(
        'OTP verification response received',
        category: 'AUTH',
      );
    } catch (error, stackTrace) {
      await AppLogger.error(
        error,
        stackTrace: stackTrace,
        reason: 'OTP verification failed',
      );
      rethrow;
    }
  }
}
