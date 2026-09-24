/// Deprecated legacy response type retained only while the previous
/// authentication feature is being replaced. New OctoGear code uses the
/// typed [ApiEnvelope] contract instead.
@Deprecated('Use ApiEnvelope for new OctoGear API code.')
class ApiResponse<T> {
  final String status;
  final String message;
  final T? data;

  ApiResponse({required this.status, required this.message, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return ApiResponse<T>(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null ? fromJsonT(json['data']) : null,
    );
  }
}
