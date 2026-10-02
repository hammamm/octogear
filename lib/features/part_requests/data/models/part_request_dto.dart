import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../domain/entities/part_request.dart';

class PartRequestDto {
  const PartRequestDto(this.command);
  final PartRequestCommand command;

  // A new multipart stream is necessary for every explicit retry.
  FormData toFormData() {
    final data = FormData.fromMap({
      'order_type': 'specific',
      'store_car_component_id': command.componentId,
      'quantity': command.quantity,
      if (command.notes.trim().isNotEmpty) 'notes': command.notes.trim(),
    });
    final photo = command.photo;
    if (photo != null) {
      final extension = switch (photo.mimeType) {
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp',
        _ => throw const FormatException('Unsupported photo.'),
      };
      data.files.add(
        MapEntry(
          'images[]',
          MultipartFile.fromBytes(
            photo.bytes,
            filename: 'part-photo.$extension',
            contentType: MediaType.parse(photo.mimeType),
          ),
        ),
      );
    }
    return data;
  }
}

PartRequestReceipt partRequestReceiptFromJson(Object? json) {
  if (json is! Map ||
      json['id'] is! int ||
      (json['id'] as int) <= 0 ||
      json['quantity'] is! int ||
      (json['quantity'] as int) <= 0 ||
      json['order_type'] != 'specific') {
    throw const FormatException('Invalid request receipt.');
  }
  return PartRequestReceipt(
    id: json['id'] as int,
    quantity: json['quantity'] as int,
  );
}
