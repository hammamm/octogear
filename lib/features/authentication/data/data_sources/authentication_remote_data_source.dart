import '../../../../core/api/api_failure.dart';
import '../../../../core/api/api_client.dart';
import '../models/authentication_dtos.dart';
import '../models/current_user_dto.dart';

/// Network-only authentication endpoints. This layer only knows endpoint
/// paths, request JSON, and DTO decoding.
abstract interface class AuthenticationRemoteDataSource {
  Future<String?> sendOtp(String mobile);
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
  Future<CityPageDto> fetchCities({String search = '', int page = 1});
}

class AuthenticationRemoteDataSourceImpl
    implements AuthenticationRemoteDataSource {
  const AuthenticationRemoteDataSourceImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<String?> sendOtp(String mobile) async {
    final response = await _apiClient.post<String?>(
      'auth/otp/send',
      data: {'mobile': mobile},
      decode: (data) {
        final code = data is Map ? data['test_otp'] : null;
        return code is String && RegExp(r'^[0-9]{4}$').hasMatch(code)
            ? code
            : null;
      },
    );
    return response.data;
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
  Future<CityPageDto> fetchCities({String search = '', int page = 1}) async {
    final response = await _apiClient.get<List<CityDto>>(
      'reference/cities',
      queryParameters: {
        'page': page,
        'per_page': 50,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
      decode: cityListFromJson,
    );
    final items = response.data;
    final meta = response.pagination;
    if (items == null ||
        meta == null ||
        meta.currentPage != page ||
        (items.isEmpty && meta.currentPage < meta.lastPage)) {
      throw const ApiFailure.unexpected();
    }
    return CityPageDto(
      items: items,
      page: meta.currentPage,
      lastPage: meta.lastPage,
    );
  }
}
