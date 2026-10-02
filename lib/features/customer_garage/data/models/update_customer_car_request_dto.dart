import '../../domain/entities/update_customer_car_command.dart';

/// Exact JSON transport contract for Laravel's customer-car PATCH endpoint.
class UpdateCustomerCarRequestDto {
  const UpdateCustomerCarRequestDto({
    required this.carNameId,
    required this.manufacturingYear,
    this.transmissionType,
    required this.colorId,
    required this.fuelTypeId,
  });

  final int carNameId;
  final int manufacturingYear;
  final String? transmissionType;
  final int colorId;
  final int fuelTypeId;

  factory UpdateCustomerCarRequestDto.fromCommand(
    UpdateCustomerCarCommand command,
  ) {
    return UpdateCustomerCarRequestDto(
      carNameId: command.carNameId,
      manufacturingYear: command.manufacturingYear,
      transmissionType: command.transmissionType,
      colorId: command.colorId,
      fuelTypeId: command.fuelTypeId,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'car_name_id': carNameId,
      'manufacturing_year': manufacturingYear,
      'transmission_type': transmissionType,
      'color_id': colorId,
      'fuel_type': fuelTypeId,
    };
  }
}
