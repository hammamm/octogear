import 'package:sahala/core/api/api_response.dart';
import 'package:sahala/features/authentication/data/models/login_request_model.dart';
import 'package:sahala/features/authentication/data/models/otp_verify_request_model.dart';
import 'package:sahala/features/authentication/data/models/otp_verify_response_model.dart';

abstract class AuthenticationRepository {
  Future<dynamic> login(LoginRequestModel body);
  Future<ApiResponse<OtpVerifyResponseModel>> otpVerify(
    OtpVerifyRequestModel body,
  );
}
