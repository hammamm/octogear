import '../../domain/entities/update_customer_profile_command.dart';

class UpdateCustomerProfileDto {
  const UpdateCustomerProfileDto(this.command);
  final UpdateCustomerProfileCommand command;

  Map<String, Object> toJson() => {
    'full_name': command.fullName,
    'city_id': command.cityId,
  };
}
