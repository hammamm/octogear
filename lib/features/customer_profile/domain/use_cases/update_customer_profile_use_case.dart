import '../../../../core/api/api_failure.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../entities/update_customer_profile_command.dart';
import '../repositories/customer_profile_repository.dart';

class UpdateCustomerProfileUseCase {
  const UpdateCustomerProfileUseCase(this._repository);
  final CustomerProfileRepository _repository;

  Future<AppUser> call(
    AppUser current,
    UpdateCustomerProfileCommand command,
  ) async {
    if (current.role != AppUserRole.customer) {
      throw const ApiFailure(type: ApiFailureType.forbidden);
    }
    final name = command.fullName.trim();
    if (name.isEmpty || name.runes.length > 100 || command.cityId < 1) {
      throw const ApiFailure(type: ApiFailureType.validation);
    }
    final saved = await _repository.update(
      UpdateCustomerProfileCommand(fullName: name, cityId: command.cityId),
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
