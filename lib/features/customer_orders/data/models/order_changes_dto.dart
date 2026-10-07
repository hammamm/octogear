import '../../domain/entities/order_changes.dart';

class OrderChangesDto {
  const OrderChangesDto(this.changes);
  final OrderChanges changes;
  Map<String, Object?> toJson() {
    final vehicle = changes.vehicle;
    return {
      if (changes.description != null) 'description': changes.description,
      if (changes.notes != null) 'notes': changes.notes,
      if (changes.quantity != null) 'quantity': changes.quantity,
      if (changes.componentName != null)
        'component_name': changes.componentName,
      if (changes.componentId != null) 'component_id': changes.componentId,
      if (vehicle != null)
        'vehicle': {
          'car_name_id': vehicle.carNameId,
          'manufacturing_year': vehicle.year,
          'transmission_type': vehicle.transmission,
          'color_id': vehicle.colorId,
          'fuel_type': vehicle.fuelTypeId,
        },
    };
  }
}
