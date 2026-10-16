import '../../domain/entities/update_provider_profile_command.dart';

class UpdateProviderProfileDto {
  const UpdateProviderProfileDto(this.command);
  final UpdateProviderProfileCommand command;

  Map<String, Object> toJson() => {
    'full_name': command.fullName,
    'city_id': command.cityId,
  };
}
