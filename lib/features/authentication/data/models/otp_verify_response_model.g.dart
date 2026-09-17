// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp_verify_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OtpVerifyResponseModel _$OtpVerifyResponseModelFromJson(
  Map<String, dynamic> json,
) => OtpVerifyResponseModel(
  customer: CustomerModel.fromJson(json['customer'] as Map<String, dynamic>),
  leadSourceList: json['leadSourceList'],
  token: json['token'] as String,
);

Map<String, dynamic> _$OtpVerifyResponseModelToJson(
  OtpVerifyResponseModel instance,
) => <String, dynamic>{
  'customer': instance.customer,
  'leadSourceList': instance.leadSourceList,
  'token': instance.token,
};
