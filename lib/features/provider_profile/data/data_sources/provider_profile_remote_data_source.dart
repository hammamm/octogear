import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../../authentication/data/models/current_user_dto.dart';
import '../models/update_provider_profile_dto.dart';

abstract interface class ProviderProfileRemoteDataSource {
  Future<CurrentUserDto> update(UpdateProviderProfileDto request);
}

class ProviderProfileRemoteDataSourceImpl
    implements ProviderProfileRemoteDataSource {
  const ProviderProfileRemoteDataSourceImpl(this._api);
  final ApiClient _api;

  @override
  Future<CurrentUserDto> update(UpdateProviderProfileDto request) async {
    final response = await _api.put<CurrentUserDto>(
      'provider/profile',
      requiresAuthentication: true,
      data: request.toJson(),
      decode: CurrentUserDto.fromJson,
    );
    return response.data ?? (throw const ApiFailure.unexpected());
  }
}
