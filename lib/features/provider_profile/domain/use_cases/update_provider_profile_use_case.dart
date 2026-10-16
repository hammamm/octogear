import '../../../../core/api/api_failure.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../entities/update_provider_profile_command.dart';
import '../repositories/provider_profile_repository.dart';

class UpdateProviderProfileUseCase {
  const UpdateProviderProfileUseCase(this._repository);
  final ProviderProfileRepository _repository;

  Future<AppUser> call(
    AppUser current,
    UpdateProviderProfileCommand command,
  ) async {
    if (current.role != AppUserRole.provider) {
      throw const ApiFailure(type: ApiFailureType.forbidden);
    }
    final name = command.fullName.trim();
    if (name.isEmpty || name.runes.length > 100 || command.cityId < 1) {
      throw const ApiFailure(type: ApiFailureType.validation);
    }
    final saved = await _repository.update(
      UpdateProviderProfileCommand(fullName: name, cityId: command.cityId),
    );
    if (saved.id != current.id ||
        saved.mobile != current.mobile ||
        saved.role != current.role ||
        saved.fullName != name ||
        saved.city?.id != command.cityId ||
        saved.city!.name.trim().isEmpty) {
      throw const ApiFailure.unexpected();
    }
    return saved;
  }
}
