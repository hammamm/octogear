import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/part_request.dart';

abstract interface class PartRequestPhotoPicker {
  Future<PartRequestPhoto?> pick();
  Future<PartRequestPhoto?> recover();
}

final partRequestPhotoPickerProvider = Provider<PartRequestPhotoPicker>(
  (ref) => GalleryPartRequestPhotoPicker(ImagePicker()),
);

class GalleryPartRequestPhotoPicker implements PartRequestPhotoPicker {
  GalleryPartRequestPhotoPicker(this._picker);
  final ImagePicker _picker;
  @override
  Future<PartRequestPhoto?> pick() async => _read(
    await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
      requestFullMetadata: false,
    ),
  );
  @override
  Future<PartRequestPhoto?> recover() async {
    final result = await _picker.retrieveLostData();
    if (result.exception != null) {
      throw const FormatException('Photo recovery failed.');
    }
    return _read(result.files?.firstOrNull);
  }

  Future<PartRequestPhoto?> _read(XFile? file) async {
    if (file == null) return null;
    final length = await file.length();
    if (length < 1 || length > 5 * 1024 * 1024) {
      throw const FormatException('Invalid image size.');
    }
    final bytes = await file.readAsBytes();
    // Inspect signatures, not personal gallery filenames or claimed MIME types.
    final mime = bytes.length >= 12
        ? switch (bytes) {
            [0xff, 0xd8, 0xff, ...] => 'image/jpeg',
            [137, 80, 78, 71, 13, 10, 26, 10, ...] => 'image/png',
            [82, 73, 70, 70, _, _, _, _, 87, 69, 66, 80, ...] => 'image/webp',
            _ => null,
          }
        : null;
    if (mime == null || bytes.length != length) {
      throw const FormatException('Invalid image.');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      try {
        if (descriptor.width > 4096 || descriptor.height > 4096) {
          throw const FormatException('Image too large.');
        }
      } finally {
        descriptor.dispose();
      }
    } finally {
      buffer.dispose();
    }
    return PartRequestPhoto(bytes: bytes, mimeType: mime);
  }
}
