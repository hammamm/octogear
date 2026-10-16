import '../../../authentication/domain/entities/app_user.dart';
import '../entities/update_provider_profile_command.dart';

abstract interface class ProviderProfileRepository {
  Future<AppUser> update(UpdateProviderProfileCommand command);
}
