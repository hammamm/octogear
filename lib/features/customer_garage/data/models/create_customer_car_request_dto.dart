import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../domain/entities/create_customer_car_command.dart';

/// Multipart transport data for creating one customer car.
///
/// It has no JSON representation because private image bytes are sent only as
/// multipart files. The idempotency key remains a request header, not body
/// data and not a URL parameter.
class CreateCustomerCarRequestDto {
  const CreateCustomerCarRequestDto({
    required this.carNameId,
    required this.manufacturingYear,
    this.transmissionType,
    required this.colorId,
    required this.fuelTypeId,
    required this.pictures,
    required this.idempotencyKey,
  });

  factory CreateCustomerCarRequestDto.fromCommand(
    CreateCustomerCarCommand command,
  ) {
    return CreateCustomerCarRequestDto(
      carNameId: command.carNameId,
      manufacturingYear: command.manufacturingYear,
      transmissionType: command.transmissionType,
      colorId: command.colorId,
      fuelTypeId: command.fuelTypeId,
      pictures: List.unmodifiable(command.pictures),
      idempotencyKey: command.idempotencyKey.trim(),
    );
  }

  final int carNameId;
  final int manufacturingYear;
  final String? transmissionType;
  final int colorId;
  final int fuelTypeId;
  final List<CustomerCarPhotoUpload> pictures;
  final String idempotencyKey;

  FormData toFormData() {
    final data = FormData();
    data.fields.addAll([
      MapEntry('car_name_id', '$carNameId'),
      MapEntry('manufacturing_year', '$manufacturingYear'),
      if (transmissionType != null)
        MapEntry('transmission_type', transmissionType!),
      MapEntry('color_id', '$colorId'),
      MapEntry('fuel_type', '$fuelTypeId'),
    ]);

    for (var index = 0; index < pictures.length; index++) {
      final picture = pictures[index];
      data.files.add(
        MapEntry(
          'pictures[]',
          MultipartFile.fromBytes(
            picture.bytes,
            // Do not transmit a source gallery filename. It can include
            // personal data and Laravel generates the final storage name.
            filename: _generatedUploadFileName(picture.mimeType, index),
            contentType: _tryParseMediaType(picture.mimeType),
          ),
        ),
      );
    }

    return data;
  }
}

MediaType? _tryParseMediaType(String value) {
  try {
    return MediaType.parse(value);
  } on FormatException {
    return null;
  }
}

String _generatedUploadFileName(String mimeType, int index) {
  final extension = switch (mimeType.toLowerCase()) {
    'image/jpeg' => 'jpg',
    'image/png' => 'png',
    'image/webp' => 'webp',
    _ => 'bin',
  };
  return 'photo-$index.$extension';
}
