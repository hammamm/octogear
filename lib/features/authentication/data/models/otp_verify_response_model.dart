import 'package:json_annotation/json_annotation.dart';
import 'package:sahala/features/authentication/data/models/customer_model.dart';

part 'otp_verify_response_model.g.dart';

@JsonSerializable()
class OtpVerifyResponseModel {
  final CustomerModel customer;
  final dynamic leadSourceList;
  final String token;

  OtpVerifyResponseModel({
    required this.customer,
    required this.leadSourceList,
    required this.token,
  });

  factory OtpVerifyResponseModel.fromJson(Map<String, dynamic> json) =>
      _$OtpVerifyResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$OtpVerifyResponseModelToJson(this);
}
