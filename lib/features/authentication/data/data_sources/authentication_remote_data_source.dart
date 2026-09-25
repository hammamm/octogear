import '../../../../core/api/api_client.dart';
import '../models/authentication_dtos.dart';
import '../models/current_user_dto.dart';

/// Network-only authentication endpoints. This layer only knows endpoint
/// paths, request JSON, and DTO decoding.
abstract interface class AuthenticationRemoteDataSource {
  Future<void> sendOtp(String mobile);
  Future<OtpVerificationDto> verifyOtp({
    required String mobile,
    required String otp,
  });
  Future<AccessTokenDto> register({
    required String temporaryRegistrationToken,
    required String fullName,
    required int cityId,
    required String? deviceToken,
  });
  Future<List<CityDto>> fetchCities();
}

class AuthenticationRemoteDataSourceImpl
    implements AuthenticationRemoteDataSource {
  const AuthenticationRemoteDataSourceImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<void> sendOtp(String mobile) async {
    await _apiClient.post<void>(
      'auth/otp/send',
      data: {'mobile': mobile},
      decode: (_) {},
    );
  }

  @override
  Future<OtpVerificationDto> verifyOtp({
    required String mobile,
    required String otp,
  }) async {
    final response = await _apiClient.post<OtpVerificationDto>(
      'auth/otp/verify',
      data: {'mobile': mobile, 'otp': otp},
      decode: OtpVerificationDto.fromJson,
    );
    final result = response.data;
    if (result == null) throw const FormatException('OTP data is missing.');
    return result;
  }

  @override
  Future<AccessTokenDto> register({
    required String temporaryRegistrationToken,
    required String fullName,
    required int cityId,
    required String? deviceToken,
  }) async {
    final data = <String, Object?>{
      'temp_token': temporaryRegistrationToken,
      'full_name': fullName,
      'city_id': cityId,
      'device_token': ?deviceToken,
    };
    final response = await _apiClient.post<AccessTokenDto>(
      'auth/register',
      data: data,
      decode: AccessTokenDto.fromJson,
    );
    final result = response.data;
    if (result == null) {
      throw const FormatException('Registration data is missing.');
    }
    return result;
  }

  @override
  Future<List<CityDto>> fetchCities() async {
    final response = await _apiClient.get<List<CityDto>>(
      'reference/cities',
      decode: cityListFromJson,
    );
    return response.data ?? const [];
  }
}
