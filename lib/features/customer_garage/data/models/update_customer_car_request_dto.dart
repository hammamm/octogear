import '../../domain/entities/update_customer_car_command.dart';

/// Exact JSON transport contract for Laravel's customer-car PATCH endpoint.
class UpdateCustomerCarRequestDto {
  const UpdateCustomerCarRequestDto({
    required this.carNameId,
    required this.manufacturingYear,
    required this.licensePlateNumber,
    required this.colorId,
    required this.fuelTypeId,
  });

  final int carNameId;
  final int manufacturingYear;
  final String licensePlateNumber;
  final int colorId;
  final int fuelTypeId;

  factory UpdateCustomerCarRequestDto.fromCommand(
    UpdateCustomerCarCommand command,
  ) {
    return UpdateCustomerCarRequestDto(
      carNameId: command.carNameId,
      manufacturingYear: command.manufacturingYear,
      licensePlateNumber: command.licensePlateNumber,
      colorId: command.colorId,
      fuelTypeId: command.fuelTypeId,
    );
  }

  Map<String, Object> toJson() {
    return {
      'car_name_id': carNameId,
      'manufacturing_year': manufacturingYear,
      'vehicle_plat_number': licensePlateNumber,
      'color_id': colorId,
      'fuel_type': fuelTypeId,
    };
  }
}
