import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'package:octogear/features/authentication/domain/entities/session_outcome.dart';
import 'package:octogear/features/authentication/presentation/controllers/session_controller.dart';
import 'package:octogear/features/seller_registration/domain/entities/seller_application.dart';
import 'package:octogear/features/seller_registration/domain/repositories/seller_registration_repository.dart';
import 'package:octogear/features/seller_registration/presentation/services/registration_document_picker.dart';

const sellerUser = AppUser(
  id: 1,
  fullName: 'Store Owner',
  mobile: '+966500000001',
  role: AppUserRole.customer,
  city: AppCity(id: 1, name: 'Riyadh'),
);
final registrationDocument = RegistrationDocument(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  ),
  'image/png',
);
SellerApplication sellerApplication({
  SellerApplicationStatus status = SellerApplicationStatus.pending,
  String name = 'Octo Parts',
  String? reason,
}) => SellerApplication(
  id: 7,
  status: status,
  name: name,
  nickname: 'Octo',
  employeeName: 'Store Owner',
  mobile: '+966500000002',
  location: 'https://maps.example.test/store',
  registrationNumber: '1234567890',
  city: sellerUser.city!,
  hasDocument: true,
  rejectionReason: reason,
);
SellerApplicationDraft sellerDraft({
  bool document = true,
  List<int> companies = const [],
}) => SellerApplicationDraft(
  name: 'Octo Parts',
  nickname: 'Octo',
  employeeName: 'Store Owner',
  location: 'https://maps.example.test/store',
  registrationNumber: '1234567890',
  cityId: 1,
  companyIds: companies,
  document: document ? registrationDocument : null,
);

class SellerSession extends SessionController {
  int refreshes = 0;
  @override
  Future<SessionOutcome> build() async =>
      const AuthenticatedSession(sellerUser);
  void replace(SessionOutcome value) => state = AsyncData(value);
  @override
  Future<void> refreshProfile({bool roleChangesOnly = false}) async {
    refreshes++;
  }
}

class FakeSellerRepository implements SellerRegistrationRepository {
  SellerApplication? current;
  Future<SellerApplication?> Function()? onLoad;
  Future<String?> Function()? onSend;
  Future<SellerApplication> Function()? onSubmit;
  int sends = 0, verifies = 0, submits = 0, corrections = 0, reads = 0;
  SellerApplicationDraft? lastDraft;
  @override
  Future<SellerApplication?> application() async {
    reads++;
    return onLoad == null ? current : await onLoad!();
  }

  @override
  Future<String?> sendCode(String mobile) async {
    sends++;
    return onSend == null ? '0042' : await onSend!();
  }

  @override
  Future<String> verifyCode(String mobile, String code) async {
    verifies++;
    return 'one-time-token';
  }

  @override
  Future<SellerApplication> submit(
    SellerApplicationDraft draft,
    String token,
  ) async {
    submits++;
    lastDraft = draft;
    return onSubmit == null
        ? current = sellerApplication(name: draft.name.trim())
        : await onSubmit!();
  }

  @override
  Future<SellerApplication> resubmit(
    int id,
    SellerApplicationDraft draft,
  ) async {
    corrections++;
    lastDraft = draft;
    return onSubmit == null
        ? current = sellerApplication(name: draft.name.trim())
        : await onSubmit!();
  }
}

class FakeRegistrationPicker implements RegistrationDocumentPicker {
  @override
  Future<RegistrationDocument?> pick() async => registrationDocument;
  @override
  Future<RegistrationDocument?> recover() async => null;
}
