import 'package:dio/dio.dart';
import 'package:sahala/core/api/api_client.dart';
import 'package:sahala/core/api/api_response.dart';
import 'package:sahala/features/authentication/data/models/login_request_model.dart';
import 'package:sahala/features/authentication/data/models/otp_verify_request_model.dart';
import 'package:sahala/features/authentication/data/models/otp_verify_response_model.dart';
import 'package:sahala/features/authentication/domain/repositories/authentication_repository.dart';

class AuthenticationRepositoryImpl implements AuthenticationRepository {
  final ApiClient apiClient = ApiClient();
  @override
  Future<dynamic> login(LoginRequestModel body) async {
    try {
      final response = await apiClient.dio.post(
        'user/loginRegister',
        data: body.toJson(),
      );
      return response;
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? e.message);
    }
  }

  @override
  Future<ApiResponse<OtpVerifyResponseModel>> otpVerify(
    OtpVerifyRequestModel body,
  ) async {
    try {
      final response = await apiClient.dio.post(
        'user/otpVerify',
        data: body.toJson(),
      );

      final json = Map<String, dynamic>.from(response.data as Map);

      return ApiResponse<OtpVerifyResponseModel>.fromJson(json, (dataJson) {
        return OtpVerifyResponseModel.fromJson(
          Map<String, dynamic>.from(dataJson as Map),
        );
      });

      // return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? e.message);
    }
  }
}
