import '../../domain/entities/provider_store_management.dart';
import 'provider_store_dto.dart';

class ProviderStoreDetailsDto {
  static ProviderStoreDetails fromJson(Object? value) {
    if (value is! Map<String, dynamic> || value['can_manage'] != true) {
      throw const FormatException('Expected owned store.');
    }
    final store = ProviderStoreDto.fromJson(value);
    if (store.cityId == null || store.city == null || store.mobile == null) {
      throw const FormatException('Incomplete store details.');
    }
    String text(String key) {
      final result = value[key];
      if (result is! String || result.trim().isEmpty) {
        throw FormatException('Missing $key.');
      }
      return result;
    }

    final companies = value['companies'];
    final pictures = value['pictures'];
    if (companies is! List || pictures is! List) {
      throw const FormatException('Missing store collections.');
    }
    final document = value['commercial_registration_picture'];
    if (document != null &&
        document != '/api/media/stores/${store.id}/registration') {
      throw const FormatException('Invalid private document.');
    }
    final version = value['edit_version'];
    final pending = value['pending_change_request_id'];
    if (version is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(version) ||
        (pending != null && (pending is! int || pending < 1))) {
      throw const FormatException('Invalid store review state.');
    }
    return ProviderStoreDetails(
      store: store,
      editVersion: version,
      pendingChangeRequestId: pending as int?,
      nickname: text('nick_name'),
      employeeName: text('employee_name'),
      registrationNumber: text('commercial_registration_number'),
      documentPath: document as String?,
      companyIds: List.unmodifiable(
        companies.map((c) {
          if (c is! Map || c['id'] is! int || c['id'] < 1) {
            throw const FormatException('Invalid company.');
          }
          return c['id'] as int;
        }),
      ),
      pictures: List.unmodifiable(
        pictures.map((p) {
          if (p is! Map ||
              p['id'] is! int ||
              p['id'] < 1 ||
              p['url'] != '/api/media/stores/${store.id}/pictures/${p['id']}') {
            throw const FormatException('Invalid private store photo.');
          }
          return ProviderStorePicture(id: p['id'], path: p['url']);
        }),
      ),
    );
  }
}
