import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahala/dependency_injection.dart';
import 'package:sahala/features/authentication/data/models/otp_verify_request_model.dart';
import 'package:sahala/features/authentication/domain/use_cases/otp_use_case.dart';
import 'dart:developer';

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
    final response = await _otpUseCase(body);
    print(response);
  }
}
