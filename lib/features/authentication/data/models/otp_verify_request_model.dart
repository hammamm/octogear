class OtpVerifyRequestModel {
  final String mobileNumber;
  final String otp;

  OtpVerifyRequestModel({required this.mobileNumber, required this.otp});
  Map<String, dynamic> toJson() {
    return {'mobile_number': mobileNumber, 'otp': otp};
  }
}
