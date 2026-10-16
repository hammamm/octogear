import '../../../../core/api/api_failure.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../domain/entities/update_provider_profile_command.dart';
import '../../domain/repositories/provider_profile_repository.dart';
import '../data_sources/provider_profile_remote_data_source.dart';
import '../models/update_provider_profile_dto.dart';

class ProviderProfileRepositoryImpl implements ProviderProfileRepository {
  const ProviderProfileRepositoryImpl(this._remote);
  final ProviderProfileRemoteDataSource _remote;

  @override
  Future<AppUser> update(UpdateProviderProfileCommand command) async {
    try {
      return (await _remote.update(
        UpdateProviderProfileDto(command),
      )).toEntity();
    } on FormatException {
      throw const ApiFailure.unexpected();
    }
  }
}
