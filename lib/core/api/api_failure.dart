import 'package:dio/dio.dart';

enum ApiFailureType {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  validation,
  rateLimited,
  timeout,
  noConnection,
  server,
  unexpected,
}

/// A typed, safe-to-present representation of a failed API request.
class ApiFailure implements Exception {
  const ApiFailure({
    required this.type,
    this.statusCode,
    this.serverMessage,
    this.fieldErrors = const {},
  });

  final ApiFailureType type;
  final int? statusCode;
  final String? serverMessage;
  final Map<String, List<String>> fieldErrors;

  factory ApiFailure.fromDio(DioException exception) {
    final response = exception.response;
    final statusCode = response?.statusCode;
    final payload = _responsePayload(response?.data);
    final message = payload['message'] is String
        ? payload['message'] as String
        : null;

    return ApiFailure(
      type: _typeFor(exception.type, statusCode),
      statusCode: statusCode,
      serverMessage: message,
      fieldErrors: statusCode == 422
          ? _fieldErrors(payload['errors'])
          : const {},
    );
  }

  const ApiFailure.unexpected({String? serverMessage})
    : this(type: ApiFailureType.unexpected, serverMessage: serverMessage);

  static ApiFailureType _typeFor(DioExceptionType exceptionType, int? status) {
    if (exceptionType == DioExceptionType.connectionTimeout ||
        exceptionType == DioExceptionType.sendTimeout ||
        exceptionType == DioExceptionType.receiveTimeout) {
      return ApiFailureType.timeout;
    }
    if (exceptionType == DioExceptionType.connectionError) {
      return ApiFailureType.noConnection;
    }

    if (status != null && status >= 500 && status <= 599) {
      return ApiFailureType.server;
    }

    return switch (status) {
      400 => ApiFailureType.badRequest,
      401 => ApiFailureType.unauthorized,
      403 => ApiFailureType.forbidden,
      404 => ApiFailureType.notFound,
      422 => ApiFailureType.validation,
      429 => ApiFailureType.rateLimited,
      _ => ApiFailureType.unexpected,
    };
  }

  static Map<String, Object?> _responsePayload(Object? value) {
    if (value is! Map) return const {};

    return Map<String, Object?>.from(value);
  }

  static Map<String, List<String>> _fieldErrors(Object? value) {
    if (value is! Map) return const {};

    final errors = <String, List<String>>{};
    for (final entry in value.entries) {
      if (entry.key is! String || entry.value is! List) continue;

      errors[entry.key as String] = (entry.value as List)
          .whereType<String>()
          .toList(growable: false);
    }
    return errors;
  }

  @override
  String toString() => 'ApiFailure(type: $type, statusCode: $statusCode)';
}
