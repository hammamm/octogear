import '../../../part_requests/domain/entities/part_request.dart';

sealed class RequestVehicle {
  const RequestVehicle();
}

class SavedRequestVehicle extends RequestVehicle {
  const SavedRequestVehicle(this.id);
  final int id;
}

class NewRequestVehicle extends RequestVehicle {
  const NewRequestVehicle({
    required this.carNameId,
    required this.year,
    required this.transmission,
    required this.colorId,
    required this.fuelTypeId,
    this.saveToGarage = false,
  });
  final int carNameId, year, colorId, fuelTypeId;
  final String transmission;
  final bool saveToGarage;
}

class RequestComponent {
  const RequestComponent({required this.id, required this.name});
  final int id;
  final String name;
}

class RequestComponentsPage {
  const RequestComponentsPage({
    required this.items,
    required this.page,
    required this.lastPage,
  });
  final List<RequestComponent> items;
  final int page, lastPage;
}

/// An immutable snapshot, including image bytes, for exact-payload retries.
class GeneralRequestCommand {
  GeneralRequestCommand({
    required this.vehicle,
    this.componentId,
    this.componentName,
    required this.description,
    required this.idempotencyKey,
    List<PartRequestPhoto> photos = const [],
  }) : photos = List.unmodifiable(photos);
  final RequestVehicle vehicle;
  final int? componentId;
  final String? componentName;
  final String description, idempotencyKey;
  final List<PartRequestPhoto> photos;
}
