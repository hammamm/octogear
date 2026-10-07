import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../domain/entities/general_request.dart';

class GeneralRequestDto {
  const GeneralRequestDto(this.command);
  final GeneralRequestCommand command;
  FormData toFormData() {
    final vehicle = command.vehicle;
    final form = FormData.fromMap({
      'order_type': 'general',
      if (vehicle is SavedRequestVehicle) 'customer_car_id': vehicle.id,
      if (vehicle is NewRequestVehicle) ...{
        'vehicle': {
          'car_name_id': vehicle.carNameId,
          'manufacturing_year': vehicle.year,
          'transmission_type': vehicle.transmission,
          'color_id': vehicle.colorId,
          'fuel_type': vehicle.fuelTypeId,
        },
        'save_to_my_cars': vehicle.saveToGarage ? '1' : '0',
      },
      if (command.componentId != null) 'component_id': command.componentId,
      if (command.componentName != null)
        'component_name': command.componentName!.trim(),
      if (command.description.trim().isNotEmpty)
        'description': command.description.trim(),
    });
    for (var i = 0; i < command.photos.length; i++) {
      final photo = command.photos[i];
      final extension = switch (photo.mimeType) {
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp',
        _ => throw const FormatException('Invalid image type.'),
      };
      form.files.add(
        MapEntry(
          'images[]',
          MultipartFile.fromBytes(
            photo.bytes,
            filename: 'part-${i + 1}.$extension',
            contentType: MediaType.parse(photo.mimeType),
          ),
        ),
      );
    }
    return form;
  }
}

int generalRequestReceipt(Object? json) {
  if (json is! Map ||
      json['id'] is! int ||
      (json['id'] as int) < 1 ||
      json['order_type'] != 'general') {
    throw const FormatException('Invalid general request receipt.');
  }
  return json['id'] as int;
}

List<RequestComponentDto> requestComponents(Object? json) {
  if (json is! List) throw const FormatException('Invalid components.');
  return List.unmodifiable(
    json.map((item) {
      if (item is! Map ||
          item['id'] is! int ||
          (item['id'] as int) < 1 ||
          item['name'] is! String ||
          (item['name'] as String).trim().isEmpty) {
        throw const FormatException('Invalid component.');
      }
      return RequestComponentDto(
        id: item['id'] as int,
        name: item['name'] as String,
      );
    }),
  );
}

class RequestComponentDto {
  const RequestComponentDto({required this.id, required this.name});
  final int id;
  final String name;
  RequestComponent toEntity() => RequestComponent(id: id, name: name);
}

class RequestComponentsPageDto {
  const RequestComponentsPageDto({
    required this.items,
    required this.page,
    required this.lastPage,
  });
  final List<RequestComponentDto> items;
  final int page, lastPage;
  RequestComponentsPage toEntity() => RequestComponentsPage(
    items: List.unmodifiable(items.map((item) => item.toEntity())),
    page: page,
    lastPage: lastPage,
  );
}
