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
  return SellerApplication(
    id: id,
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
