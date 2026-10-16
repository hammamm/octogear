import '../../domain/entities/provider_store_management.dart';

class ProviderStoreWriteDto {
  const ProviderStoreWriteDto(this.draft);
  final ProviderStoreDraft draft;
  Map<String, Object?> fields({bool includeMobile = true}) => {
    'name': draft.details.name.trim(),
    'nick_name': draft.details.nickname.trim(),
    'employee_name': draft.details.employeeName.trim(),
    'url_location': draft.details.location.trim(),
    'commercial_registration_number': draft.details.registrationNumber.trim(),
    'city_id': draft.details.cityId,
    'company_ids': draft.details.companyIds.isEmpty
        ? ''
        : draft.details.companyIds,
    if (includeMobile) 'mobile': draft.normalizedMobile,
  };
}
