import 'dart:convert';
import 'package:octogear/features/authentication/domain/entities/app_user.dart';
import 'package:octogear/features/provider_stores/domain/entities/provider_store_management.dart';
import 'package:octogear/features/provider_stores/domain/repositories/provider_store_management_repository.dart';
import 'package:octogear/features/seller_registration/domain/entities/seller_application.dart';
import 'provider_stores_fixtures.dart';

const managedStore = ProviderStoreDetails(
  store: store,
  editVersion:
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  nickname: 'Al Faris',
  employeeName: 'Store Manager',
  registrationNumber: '1234567890',
  companyIds: [1, 2],
  pictures: [],
);
const rejectedApplication = SellerApplication(
  id: 11,
  status: SellerApplicationStatus.rejected,
  name: 'Another Store',
  nickname: 'Another',
  employeeName: 'Manager',
  mobile: '+966522222222',
  location: 'https://maps.example.test/store',
  registrationNumber: '1234567890',
  city: AppCity(id: 1, name: 'Riyadh'),
  hasDocument: true,
  rejectionReason: 'Please correct the name.',
  companyIds: [1],
);
final imageDocument = RegistrationDocument(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAF/gL+9/3K8QAAAABJRU5ErkJggg==',
  ),
  'image/png',
);
const requestKey = 'e1cd5257-7379-4662-a716-2b892e47ee11';
ProviderStoreDraft storeDraft({
  String name = 'Al Faris Parts',
  String mobile = '+966522222222',
  bool document = false,
}) => ProviderStoreDraft(
  mobile: mobile,
  changeReason: 'We changed our trading name.',
  baseVersion: managedStore.editVersion,
  details: SellerApplicationDraft(
    name: name,
    nickname: 'Al Faris',
    employeeName: 'Manager',
    location: 'https://maps.example.test/store',
    registrationNumber: '1234567890',
    cityId: 1,
    companyIds: [1, 2],
    document: document ? imageDocument : null,
  ),
);
SellerApplication pendingApplication(
  ProviderStoreDraft draft, {
  int? storeId,
  String submissionKey = requestKey,
}) => SellerApplication(
  id: 11,
  storeId: storeId,
  changeReason: storeId == null ? null : draft.changeReason,
  idempotencyKey: submissionKey,
  status: SellerApplicationStatus.pending,
  name: draft.details.name,
  nickname: draft.details.nickname,
  employeeName: draft.details.employeeName,
  mobile: draft.normalizedMobile!,
  location: draft.details.location,
  registrationNumber: draft.details.registrationNumber,
  city: const AppCity(id: 1, name: 'Riyadh'),
  hasDocument: true,
  companyIds: draft.details.companyIds,
);

class FakeStoreManagement implements ProviderStoreManagementRepository {
  int writes = 0, reads = 0;
  ProviderStoreDraft? lastDraft;
  String? lastKey;
  ProviderStoreDetails details = managedStore;
  List<SellerApplication> applications = [rejectedApplication];
  Future<SellerApplication> Function()? onUpdate;
  Future<SellerApplication> Function()? onSubmit;
  @override
  Future<ProviderStoreDetails> fetchStore(int id) async {
    reads++;
    return details;
  }

  @override
  Future<SellerApplication> requestStoreChange(
    int id,
    ProviderStoreDraft draft,
    String key,
  ) async {
    writes++;
    lastDraft = draft;
    lastKey = key;
    if (onUpdate != null) return onUpdate!();
    final saved = pendingApplication(draft, storeId: id, submissionKey: key);
    applications = [saved];
    return saved;
  }

  @override
  Future<List<SellerApplication>> fetchApplications() async {
    reads++;
    return applications;
  }

  @override
  Future<SellerApplication> fetchApplication(int id) async {
    reads++;
    return applications.singleWhere((a) => a.id == id);
  }

  @override
  Future<SellerApplication> submitApplication(
    ProviderStoreDraft draft,
    String key,
  ) async {
    writes++;
    lastDraft = draft;
    lastKey = key;
    if (onSubmit != null) return onSubmit!();
    final saved = pendingApplication(draft, submissionKey: key);
    applications = [saved];
    return saved;
  }

  @override
  Future<SellerApplication> resubmitApplication(
    int id,
    ProviderStoreDraft draft,
  ) => submitApplication(draft, requestKey);
}
