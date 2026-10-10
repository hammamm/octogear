import 'dart:typed_data';

import '../../../authentication/domain/entities/app_user.dart';

enum SellerApplicationStatus { pending, accepted, rejected }

class RegistrationDocument {
  const RegistrationDocument(this.bytes, this.mimeType);
  final Uint8List bytes;
  final String mimeType;
}

class SellerApplication {
  const SellerApplication({
    required this.id,
    required this.status,
    required this.name,
    required this.nickname,
    required this.employeeName,
    required this.mobile,
    required this.location,
    required this.registrationNumber,
    required this.city,
    required this.hasDocument,
    this.rejectionReason,
    this.companyIds = const [],
  });
  final int id;
  final SellerApplicationStatus status;
  final String name,
      nickname,
      employeeName,
      mobile,
      location,
      registrationNumber;
  final AppCity city;
  final bool hasDocument;
  final String? rejectionReason;
  final List<int> companyIds;
}

class SellerApplicationDraft {
  const SellerApplicationDraft({
    required this.name,
    required this.nickname,
    required this.employeeName,
    required this.location,
    required this.registrationNumber,
    required this.cityId,
    this.document,
    this.companyIds = const [],
  });
  final String name, nickname, employeeName, location, registrationNumber;
  final int cityId;
  final RegistrationDocument? document;
  final List<int> companyIds;

  bool get isValid =>
      [
        name,
        nickname,
        employeeName,
      ].every((v) => v.trim().isNotEmpty && v.runes.length <= 100) &&
      registrationNumber.trim().isNotEmpty &&
      registrationNumber.runes.length <= 50 &&
      cityId > 0 &&
      companyIds.length <= 100 &&
      companyIds.every((id) => id > 0) &&
      companyIds.toSet().length == companyIds.length &&
      validStoreLocation(location);
}

bool validStoreLocation(String value) {
  final uri = Uri.tryParse(value.trim());
  return value.length <= 255 &&
      uri != null &&
      uri.scheme == 'https' &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty;
}
