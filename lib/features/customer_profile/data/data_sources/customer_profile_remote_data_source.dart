import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../../authentication/data/models/current_user_dto.dart';
import '../models/update_customer_profile_dto.dart';

abstract interface class CustomerProfileRemoteDataSource {
  Future<CurrentUserDto> update(UpdateCustomerProfileDto request);
}

class CustomerProfileRemoteDataSourceImpl
    implements CustomerProfileRemoteDataSource {
  const CustomerProfileRemoteDataSourceImpl(this._api);
  final ApiClient _api;

  @override
  Future<CurrentUserDto> update(UpdateCustomerProfileDto request) async {
    final response = await _api.patch<CurrentUserDto>(
      'customer/profile',
      requiresAuthentication: true,
      data: request.toJson(),
      decode: CurrentUserDto.fromJson,
    );
    return response.data ?? (throw const ApiFailure.unexpected());
  }
}
