import '../../../../core/api/api_failure.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../domain/entities/update_customer_profile_command.dart';
import '../../domain/repositories/customer_profile_repository.dart';
import '../data_sources/customer_profile_remote_data_source.dart';
import '../models/update_customer_profile_dto.dart';

class CustomerProfileRepositoryImpl implements CustomerProfileRepository {
  const CustomerProfileRepositoryImpl(this._remote);
  final CustomerProfileRemoteDataSource _remote;

  @override
  Future<AppUser> update(UpdateCustomerProfileCommand command) async {
    try {
      return (await _remote.update(
        UpdateCustomerProfileDto(command),
      )).toEntity();
    } on FormatException {
      throw const ApiFailure.unexpected();
    }
  }
}
