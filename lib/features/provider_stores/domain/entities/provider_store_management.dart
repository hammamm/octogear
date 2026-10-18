import '../../../../core/media/image_upload_policy.dart';
import '../../../authentication/domain/entities/app_user.dart';
import '../../../authentication/domain/entities/saudi_mobile_number.dart';
import '../../../seller_registration/domain/entities/seller_application.dart';
import 'provider_store.dart';

class ProviderStorePicture {
  const ProviderStorePicture({required this.id, required this.path});
  final int id;
  final String path;
}

class ProviderStoreDetails {
  const ProviderStoreDetails({
    required this.store,
    required this.nickname,
    required this.employeeName,
    required this.registrationNumber,
    required this.companyIds,
    required this.pictures,
    this.documentPath,
    this.editVersion = '',
    this.pendingChangeRequestId,
  });
  final ProviderStore store;
  final String nickname, employeeName, registrationNumber;
  final String? documentPath;
  final String editVersion;
  final int? pendingChangeRequestId;
  final List<int> companyIds;
  final List<ProviderStorePicture> pictures;
  AppCity get city => AppCity(id: store.cityId!, name: store.city!);
}

/// One form model for an owned store or its approval application.
class ProviderStoreDraft {
  const ProviderStoreDraft({
    required this.details,
    required this.mobile,
    this.retainedPictureIds = const [],
    this.pictures = const [],
    this.changeReason = '',
    this.baseVersion = '',
  });
  final SellerApplicationDraft details;
  final String mobile;
  final String changeReason, baseVersion;
  bool get isValidChange =>
      isValid &&
      changeReason.trim().runes.length >= 10 &&
      changeReason.trim().runes.length <= 1000 &&
      RegExp(r'^[a-f0-9]{64}$').hasMatch(baseVersion);
  final List<int> retainedPictureIds;
  final List<RegistrationDocument> pictures;
  String? get normalizedMobile {
    final number = SaudiMobileNumber.tryParse(mobile);
    return number == null ? null : '+966${number.nationalNumber}';
  }

  bool get isValid =>
      details.isValid &&
      normalizedMobile != null &&
      retainedPictureIds.length + pictures.length <=
          ImageUploadPolicy.maxFiles &&
      retainedPictureIds.every((id) => id > 0) &&
      retainedPictureIds.toSet().length == retainedPictureIds.length &&
      [if (details.document != null) details.document!, ...pictures].every(
        (image) =>
            image.bytes.isNotEmpty &&
            image.bytes.length <= ImageUploadPolicy.maxBytes &&
            ImageUploadPolicy.mimeTypes.contains(image.mimeType),
      );
}
