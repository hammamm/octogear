/// Only fields supported by an order edit, independent of API key names.
class OrderChanges {
  const OrderChanges({
    this.description,
    this.notes,
    this.quantity,
    this.vehicle,
    this.componentName,
    this.componentId,
  }) : assert(componentName == null || componentId == null);
  final String? description, notes, componentName;
  final int? quantity, componentId;
  final OrderVehicleChanges? vehicle;
}

class OrderVehicleChanges {
  const OrderVehicleChanges({
    required this.carNameId,
    required this.year,
    required this.transmission,
    required this.colorId,
    required this.fuelTypeId,
  });
  final int carNameId, year, colorId, fuelTypeId;
  final String transmission;
}
