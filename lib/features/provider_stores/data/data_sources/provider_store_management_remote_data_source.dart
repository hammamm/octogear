import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../../seller_registration/data/models/seller_application_dto.dart';
import '../../../seller_registration/domain/entities/seller_application.dart';
import '../../domain/entities/provider_store_management.dart';
import '../models/provider_store_details_dto.dart';
import '../models/provider_store_write_dto.dart';

class ProviderStoreManagementRemoteDataSource {
  const ProviderStoreManagementRemoteDataSource(this._api);
  final ApiClient _api;
  Future<ProviderStoreDetails> fetchStore(int id) async {
    final response = await _api.get(
      'provider/stores/$id',
      requiresAuthentication: true,
      decode: ProviderStoreDetailsDto.fromJson,
    );
    return response.data ?? (throw const ApiFailure.unexpected());
  }

  Future<List<SellerApplication>> fetchApplications() async {
    final response = await _api.get(
      'provider/store-requests',
      requiresAuthentication: true,
      decode: (value) {
        if (value is! List) {
          throw const FormatException('Invalid applications.');
        }
        return List<SellerApplication>.unmodifiable(
          value.map(sellerApplicationFromJson),
        );
      },
    );
    return response.data ?? (throw const ApiFailure.unexpected());
  }

  Future<SellerApplication> fetchApplication(int id) async {
    final response = await _api.get(
      'provider/store-requests/$id',
      requiresAuthentication: true,
      decode: sellerApplicationFromJson,
    );
    return response.data ?? (throw const ApiFailure.unexpected());
  }

  MultipartFile _file(RegistrationDocument document) => MultipartFile.fromBytes(
    document.bytes,
    filename: 'image.${document.mimeType.split('/').last}',
    contentType: DioMediaType.parse(document.mimeType),
  );
  FormData _form(
    ProviderStoreWriteDto request, {
    bool update = false,
    bool resubmit = false,
    String? key,
  }) {
    final draft = request.draft;
    return FormData.fromMap({
      ...request.fields(includeMobile: !resubmit && !update),
      'idempotency_key': ?key,
      if (update) 'change_reason': draft.changeReason.trim(),
      if (update) 'base_version': draft.baseVersion,
      if (update)
        'retained_picture_ids': draft.retainedPictureIds.isEmpty
            ? ''
            : draft.retainedPictureIds,
      if (update && draft.pictures.isNotEmpty)
        'pictures': draft.pictures.map(_file).toList(),
      if (draft.details.document != null)
        'commercial_registration_picture': _file(draft.details.document!),
    }, ListFormat.multiCompatible);
  }

  Future<SellerApplication> requestStoreChange(
    int id,
    ProviderStoreWriteDto request,
    String key,
  ) async {
    final response = await _api.postMultipart(
      'provider/stores/$id/change-requests',
      requiresAuthentication: true,
      data: _form(request, update: true, key: key),
      decode: sellerApplicationFromJson,
    );
    return response.data ?? (throw const ApiFailure.unexpected());
  }

  Future<SellerApplication> submitApplication(
    ProviderStoreWriteDto request,
    String key,
  ) async {
    final response = await _api.postMultipart(
      'provider/store-requests/direct',
      requiresAuthentication: true,
      data: _form(request, key: key),
      decode: sellerApplicationFromJson,
    );
    return response.data ?? (throw const ApiFailure.unexpected());
  }

  Future<SellerApplication> resubmitApplication(
    int id,
    ProviderStoreWriteDto request,
  ) async {
    final response = await _api.postMultipart(
      'provider/store-requests/$id/resubmit',
      requiresAuthentication: true,
      data: _form(request, resubmit: true),
      decode: sellerApplicationFromJson,
    );
    return response.data ?? (throw const ApiFailure.unexpected());
  }
}
