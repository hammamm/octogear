import '../entities/general_request.dart';
import '../repositories/general_request_repository.dart';

class SendGeneralRequest {
  const SendGeneralRequest(this.repository);
  final GeneralRequestRepository repository;
  Future<int> call(GeneralRequestCommand command) {
    final vehicle = command.vehicle;
    if ((command.componentId == null) == (command.componentName == null) ||
        (command.componentId != null && command.componentId! < 1) ||
        (command.componentName != null &&
            (command.componentName!.trim().isEmpty ||
                command.componentName!.runes.length > 255)) ||
        command.description.runes.length > 1000 ||
        command.idempotencyKey.isEmpty ||
        command.photos.length > 5 ||
        command.photos.any(
          (p) =>
              p.bytes.isEmpty ||
              p.bytes.length > 5 * 1024 * 1024 ||
              !['image/jpeg', 'image/png', 'image/webp'].contains(p.mimeType),
        ) ||
        (vehicle is SavedRequestVehicle && vehicle.id < 1) ||
        (vehicle is NewRequestVehicle &&
            (vehicle.carNameId < 1 ||
                vehicle.colorId < 1 ||
                vehicle.fuelTypeId < 1 ||
                vehicle.year < 1970 ||
                vehicle.year > DateTime.now().year ||
                ![
                  'manual',
                  'automatic',
                  'unknown',
                ].contains(vehicle.transmission)))) {
      throw ArgumentError('Invalid general request.');
    }
    return repository.submit(command);
  }
}
