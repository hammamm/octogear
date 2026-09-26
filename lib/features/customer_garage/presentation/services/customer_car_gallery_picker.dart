import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/create_customer_car_command.dart';

const customerCarPhotoLimit = 5;
const customerCarPhotoMaximumBytes = 5 * 1024 * 1024;

final customerCarGalleryPickerProvider = Provider<CustomerCarGalleryPicker>((
  ref,
) {
  return ImagePickerCustomerCarGalleryPicker(ImagePicker());
});

/// The selected image data which presentation may safely keep until submit.
///
/// File-system paths and gallery names never leave this service. Only bytes and
/// a checked MIME type reach the feature's domain command.
class CustomerCarPhotoSelection {
  const CustomerCarPhotoSelection({
    required this.photos,
    this.rejectedPhotoCount = 0,
  });

  final List<CustomerCarPhotoUpload> photos;
  final int rejectedPhotoCount;
}

abstract interface class CustomerCarGalleryPicker {
  Future<CustomerCarPhotoSelection> pickPhotos({required int limit});

  /// Recovers an Android picker result after the app activity was recreated.
  Future<CustomerCarPhotoSelection> recoverLostPhotos();
}

class CustomerCarGalleryPickerException implements Exception {
  const CustomerCarGalleryPickerException();
}

class ImagePickerCustomerCarGalleryPicker implements CustomerCarGalleryPicker {
  ImagePickerCustomerCarGalleryPicker(this._picker);

  final ImagePicker _picker;

  @override
  Future<CustomerCarPhotoSelection> pickPhotos({required int limit}) async {
    if (limit <= 0) return const CustomerCarPhotoSelection(photos: []);

    try {
      final files = await _picker.pickMultiImage(
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
        limit: limit,
        requestFullMetadata: false,
      );
      return await _toSelection(files, limit: limit);
    } catch (_) {
      throw const CustomerCarGalleryPickerException();
    }
  }

  @override
  Future<CustomerCarPhotoSelection> recoverLostPhotos() async {
    try {
      final response = await _picker.retrieveLostData();
      if (response.isEmpty) {
        return const CustomerCarPhotoSelection(photos: []);
      }

      if (response.exception != null) {
        throw const CustomerCarGalleryPickerException();
      }

      return await _toSelection(
        response.files ?? const [],
        limit: customerCarPhotoLimit,
      );
    } catch (error) {
      if (error is CustomerCarGalleryPickerException) rethrow;
      throw const CustomerCarGalleryPickerException();
    }
  }

  Future<CustomerCarPhotoSelection> _toSelection(
    List<XFile> files, {
    required int limit,
  }) async {
    final photos = <CustomerCarPhotoUpload>[];
    var rejectedPhotoCount = 0;

    for (final file in files) {
      final mimeType = _supportedMimeType(file);
      if (mimeType == null || photos.length >= limit) {
        rejectedPhotoCount++;
        continue;
      }

      try {
        final byteLength = await file.length();
        if (byteLength <= 0 || byteLength > customerCarPhotoMaximumBytes) {
          rejectedPhotoCount++;
          continue;
        }

        final bytes = await file.readAsBytes();
        if (bytes.lengthInBytes != byteLength) {
          rejectedPhotoCount++;
          continue;
        }

        photos.add(CustomerCarPhotoUpload(bytes: bytes, mimeType: mimeType));
      } catch (_) {
        rejectedPhotoCount++;
      }
    }

    return CustomerCarPhotoSelection(
      photos: List.unmodifiable(photos),
      rejectedPhotoCount: rejectedPhotoCount,
    );
  }

  String? _supportedMimeType(XFile file) {
    final declaredType = file.mimeType?.toLowerCase();
    if (_supportedMimeTypes.contains(declaredType)) return declaredType;

    // Some Android gallery providers omit MIME metadata. Use only the local
    // extension to classify the temporary file; its original name is never
    // retained or uploaded. Laravel independently validates the actual bytes.
    final lowerCaseName = file.name.toLowerCase();
    if (lowerCaseName.endsWith('.jpg') || lowerCaseName.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lowerCaseName.endsWith('.png')) return 'image/png';
    if (lowerCaseName.endsWith('.webp')) return 'image/webp';
    return null;
  }
}

const _supportedMimeTypes = <String>{'image/jpeg', 'image/png', 'image/webp'};
