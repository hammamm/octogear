/// The editable scalar values of a saved customer car.
///
/// Existing private photos are intentionally not part of this command. Their
/// mutation needs a separate idempotency contract before it is exposed in the
/// app, while this PATCH operation is naturally safe to repeat.
class UpdateCustomerCarCommand {
  const UpdateCustomerCarCommand({
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
}
