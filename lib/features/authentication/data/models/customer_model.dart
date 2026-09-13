import 'package:json_annotation/json_annotation.dart';

part 'customer_model.g.dart';

@JsonSerializable()
class CustomerModel {
  final String? createdAt;
  final String? customerBlockStatus;
  final String? customerStatus;
  final String? dateOfBirth;
  final String? deviceToken;
  final String? deviceType;
  final String? fullName;
  final int? id;
  final String? iqamaNumber;
  final String? latitude;
  final String? longitude;
  final String? mobileNumber;
  final String? otp;
  final int? otpVerify;
  final int? profileCompleteStatus;
  final dynamic referralCode;
  final String? title;
  final String? updatedAt;

  CustomerModel({
    this.createdAt,
    this.customerBlockStatus,
    this.customerStatus,
    this.dateOfBirth,
    this.deviceToken,
    this.deviceType,
    this.fullName,
    this.id,
    this.iqamaNumber,
    this.latitude,
    this.longitude,
    this.mobileNumber,
    this.otp,
    this.otpVerify,
    this.profileCompleteStatus,
    this.referralCode,
    this.title,
    this.updatedAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerModelFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerModelToJson(this);
}
