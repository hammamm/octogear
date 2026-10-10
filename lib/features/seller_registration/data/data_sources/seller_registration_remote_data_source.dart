import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../domain/entities/seller_application.dart';
import '../models/seller_application_dto.dart';

class SellerRegistrationRemoteDataSource {
  const SellerRegistrationRemoteDataSource(this.api);
  final ApiClient api;

  Future<SellerApplication?> application() async =>
      (await api.get<SellerApplication?>(
        'seller-application',
        requiresAuthentication: true,
        decode: (data) => data == null ? null : sellerApplicationFromJson(data),
      )).data;

  Future<String?> sendCode(String mobile) async => (await api.post<String?>(
    'provider/store-requests/verify-mobile',
    requiresAuthentication: true,
    data: {'mobile': mobile},
    decode: (value) {
      final code = value is Map ? value['test_otp'] : null;
      return code is String && RegExp(r'^\d{4}$').hasMatch(code) ? code : null;
    },
  )).data;

  Future<String> verifyCode(String mobile, String code) async {
    final response = await api.post<String>(
      'provider/store-requests/verify-code',
      requiresAuthentication: true,
      data: {'mobile': mobile, 'otp': code},
      decode: (value) {
        final token = value is Map ? value['temp_token'] : null;
        if (token is! String || token.isEmpty) {
          throw const FormatException('Missing verification token.');
        }
        return token;
      },
    );
    return response.data ?? (throw const ApiFailure.unexpected());
  }

  Future<SellerApplication> submit(
    SellerApplicationDraft draft, {
    String? token,
    int? requestId,
  }) async {
    final photo = draft.document;
    final fields = <String, Object?>{
      'name': draft.name.trim(),
      'nick_name': draft.nickname.trim(),
      'employee_name': draft.employeeName.trim(),
      'url_location': draft.location.trim(),
      'commercial_registration_number': draft.registrationNumber.trim(),
      'city_id': draft.cityId,
      'company_ids': draft.companyIds.isEmpty ? '' : draft.companyIds,
      'temp_token': ?token,
      if (photo != null)
        'commercial_registration_picture': MultipartFile.fromBytes(
          photo.bytes,
          filename:
              'registration.${photo.mimeType.split('/').last == 'jpeg' ? 'jpg' : photo.mimeType.split('/').last}',
          contentType: MediaType.parse(photo.mimeType),
        ),
    };
    final response = await api.postMultipart<SellerApplication>(
      requestId == null
          ? 'provider/store-requests'
          : 'customer/seller-application/$requestId/resubmit',
      requiresAuthentication: true,
      data: FormData.fromMap(fields, ListFormat.multiCompatible),
      decode: (value) => sellerApplicationFromJson(
        requestId == null && value is Map ? value['store_request'] : value,
      ),
    );
    return response.data ?? (throw const ApiFailure.unexpected());
  }
}
