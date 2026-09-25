import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../models/current_user_dto.dart';

/// Network-only contract for the shared authenticated user profile.
abstract interface class ProfileRemoteDataSource {
  Future<CurrentUserDto> fetchProfile();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  const ProfileRemoteDataSourceImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<CurrentUserDto> fetchProfile() async {
    final response = await _apiClient.get<CurrentUserDto>(
      'profile',
      requiresAuthentication: true,
      decode: CurrentUserDto.fromJson,
    );
    final profile = response.data;
    if (profile == null) throw const ApiFailure.unexpected();
    return profile;
  }
}
