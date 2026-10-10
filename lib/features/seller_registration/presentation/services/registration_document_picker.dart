import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/seller_application.dart';

abstract interface class RegistrationDocumentPicker {
  Future<RegistrationDocument?> pick();
  Future<RegistrationDocument?> recover();
}

final registrationDocumentPickerProvider = Provider<RegistrationDocumentPicker>(
  (ref) => GalleryRegistrationDocumentPicker(ImagePicker()),
);

class GalleryRegistrationDocumentPicker implements RegistrationDocumentPicker {
  GalleryRegistrationDocumentPicker(this.picker);
  final ImagePicker picker;
  @override
  Future<RegistrationDocument?> pick() async => _read(
    await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 90,
      requestFullMetadata: false,
    ),
  );
  @override
  Future<RegistrationDocument?> recover() async {
    final result = await picker.retrieveLostData();
    if (result.exception != null) {
      throw const FormatException('Document recovery failed.');
    }
    return _read(result.files?.firstOrNull);
  }

  Future<RegistrationDocument?> _read(XFile? file) async {
    if (file == null) return null;
    if (await file.length() > 5 * 1024 * 1024) {
      throw const FormatException('Document too large.');
    }
    final bytes = await file.readAsBytes();
    final mime = switch (bytes) {
      [255, 216, 255, ...] => 'image/jpeg',
      [137, 80, 78, 71, 13, 10, 26, 10, ...] => 'image/png',
      [82, 73, 70, 70, _, _, _, _, 87, 69, 66, 80, ...] => 'image/webp',
      _ => throw const FormatException('Unsupported document.'),
    };
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw const FormatException('Invalid document size.');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      try {
        if (descriptor.width < 1 ||
            descriptor.height < 1 ||
            descriptor.width > 4096 ||
            descriptor.height > 4096) {
          throw const FormatException('Invalid document dimensions.');
        }
      } finally {
        descriptor.dispose();
      }
    } finally {
      buffer.dispose();
    }
    return RegistrationDocument(bytes, mime);
  }
}
