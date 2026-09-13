// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerModel _$CustomerModelFromJson(Map<String, dynamic> json) =>
    CustomerModel(
      createdAt: json['createdAt'] as String?,
      customerBlockStatus: json['customerBlockStatus'] as String?,
      customerStatus: json['customerStatus'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      deviceToken: json['deviceToken'] as String?,
      deviceType: json['deviceType'] as String?,
      fullName: json['fullName'] as String?,
      id: (json['id'] as num?)?.toInt(),
      iqamaNumber: json['iqamaNumber'] as String?,
      latitude: json['latitude'] as String?,
      longitude: json['longitude'] as String?,
      mobileNumber: json['mobileNumber'] as String?,
      otp: json['otp'] as String?,
      otpVerify: (json['otpVerify'] as num?)?.toInt(),
      profileCompleteStatus: (json['profileCompleteStatus'] as num?)?.toInt(),
      referralCode: json['referralCode'],
      title: json['title'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$CustomerModelToJson(CustomerModel instance) =>
    <String, dynamic>{
      'createdAt': instance.createdAt,
      'customerBlockStatus': instance.customerBlockStatus,
      'customerStatus': instance.customerStatus,
      'dateOfBirth': instance.dateOfBirth,
      'deviceToken': instance.deviceToken,
      'deviceType': instance.deviceType,
      'fullName': instance.fullName,
      'id': instance.id,
      'iqamaNumber': instance.iqamaNumber,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'mobileNumber': instance.mobileNumber,
      'otp': instance.otp,
      'otpVerify': instance.otpVerify,
      'profileCompleteStatus': instance.profileCompleteStatus,
      'referralCode': instance.referralCode,
      'title': instance.title,
      'updatedAt': instance.updatedAt,
    };
