import '../../../authentication/domain/entities/app_user.dart';
import '../../domain/entities/seller_application.dart';

SellerApplication sellerApplicationFromJson(Object? value) {
  if (value is! Map) throw const FormatException('Invalid application.');
  String text(String key) {
    final field = value[key];
    if (field is! String || field.trim().isEmpty) {
      throw FormatException('Invalid $key.');
    }
    return field;
  }

  final id = value['id'];
  final city = value['city'];
  if (id is! int ||
      id < 1 ||
      city is! Map ||
      city['id'] is! int ||
      city['id'] < 1 ||
      city['name'] is! String ||
      (city['name'] as String).trim().isEmpty) {
    throw const FormatException('Invalid application identity.');
  }
  final status = switch (value['request_status']) {
    'pending' => SellerApplicationStatus.pending,
    'accepted' => SellerApplicationStatus.accepted,
    'rejected' => SellerApplicationStatus.rejected,
    _ => throw const FormatException('Unknown application status.'),
  };
  final storeId = value['store_id'];
  final reason = value['change_reason'];
  if (storeId != null &&
      (storeId is! int ||
          storeId < 1 ||
          reason is! String ||
          reason.trim().isEmpty)) {
    throw const FormatException('Invalid store change request.');
  }
  final pictures = value['pictures'] ?? const [];
  if (pictures is! List) throw const FormatException('Invalid request photos.');
  final paths = pictures
      .map((p) {
        if (p is! Map ||
            p['id'] is! int ||
            p['id'] < 1 ||
            p['url'] != '/api/media/store-requests/$id/pictures/${p['id']}') {
          throw const FormatException('Invalid private request photo.');
        }
        return p['url'] as String;
      })
      .toList(growable: false);
  return SellerApplication(
    id: id,
    storeId: storeId as int?,
    changeReason: reason as String?,
    idempotencyKey: value['idempotency_key'] as String?,
    picturePaths: List.unmodifiable(paths),
    status: status,
    name: text('name'),
    nickname: text('nick_name'),
    employeeName: text('employee_name'),
    mobile: text('mobile'),
    location: text('url_location'),
    registrationNumber: text('commercial_registration_number'),
    city: AppCity(id: city['id'], name: city['name']),
    companyIds: (value['company_ids'] as List? ?? const [])
        .map((id) {
          if (id is! int || id < 1) {
            throw const FormatException('Invalid manufacturer.');
          }
          return id;
        })
        .toList(growable: false),
    hasDocument:
        value['commercial_registration_picture'] is String &&
        (value['commercial_registration_picture'] as String).isNotEmpty,
    rejectionReason: value['rejection_reason'] is String
        ? value['rejection_reason']
        : null,
  );
}
