/// The standard Laravel response envelope used by OctoGear endpoints.
class ApiEnvelope<T> {
  const ApiEnvelope({required this.success, required this.message, this.data});

  final bool success;
  final String message;
  final T? data;

  factory ApiEnvelope.fromJson(
    Map<String, Object?> json,
    T Function(Object? data) fromData,
  ) {
    final success = json['success'];
    if (success is! bool) {
      throw const ApiContractException(
        'The response has no boolean success value.',
      );
    }

    final message = json['message'];
    return ApiEnvelope(
      success: success,
      message: message is String ? message : '',
      data: json['data'] == null ? null : fromData(json['data']),
    );
  }
}

class ApiContractException implements Exception {
  const ApiContractException(this.message);

  final String message;

  @override
  String toString() => 'ApiContractException: $message';
}
