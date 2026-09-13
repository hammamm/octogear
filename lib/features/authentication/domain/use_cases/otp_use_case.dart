import 'package:sahala/core/api/api_response.dart';
import 'package:sahala/features/authentication/data/models/otp_verify_request_model.dart';
import 'package:sahala/features/authentication/data/models/otp_verify_response_model.dart';
import 'package:sahala/features/authentication/domain/repositories/authentication_repository.dart';

class OtpUseCase {
  final AuthenticationRepository repository;

  OtpUseCase({required this.repository});

  Future<ApiResponse<OtpVerifyResponseModel>> call(
    OtpVerifyRequestModel body,
  ) async {
    return await repository.otpVerify(body);
  }
}
