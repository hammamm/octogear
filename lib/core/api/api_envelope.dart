/// The standard Laravel response envelope used by OctoGear endpoints.
class ApiEnvelope<T> {
  const ApiEnvelope({
    required this.success,
    required this.message,
    this.data,
    this.pagination,
  });

  final bool success;
  final String message;
  final T? data;
  final ApiPaginationMeta? pagination;

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
      pagination: json['meta'] == null
          ? null
          : ApiPaginationMeta.fromJson(json['meta']),
    );
  }
}

/// Typed pagination metadata supplied by Laravel list endpoints.
///
/// Features map this transport value to their own domain page object. Keeping
/// the parser here means every paginated endpoint validates the common API
/// contract consistently instead of treating metadata as untyped JSON.
class ApiPaginationMeta {
  const ApiPaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  factory ApiPaginationMeta.fromJson(Object? value) {
    if (value is! Map) {
      throw const ApiContractException('Pagination metadata is not an object.');
    }

    final json = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw const ApiContractException(
          'Pagination metadata has a non-string key.',
        );
      }
      json[entry.key as String] = entry.value;
    }

    final currentPage = _positiveInteger(json['current_page'], 'current_page');
    final lastPage = _positiveInteger(json['last_page'], 'last_page');
    final perPage = _positiveInteger(json['per_page'], 'per_page');
    final total = _nonNegativeInteger(json['total'], 'total');
    if (currentPage > lastPage) {
      throw const ApiContractException(
        'Pagination current_page exceeds last_page.',
      );
    }

    return ApiPaginationMeta(
      currentPage: currentPage,
      lastPage: lastPage,
      perPage: perPage,
      total: total,
    );
  }
}

int _positiveInteger(Object? value, String fieldName) {
  final result = _integer(value, fieldName);
  if (result <= 0) {
    throw ApiContractException('Pagination $fieldName must be positive.');
  }
  return result;
}

int _nonNegativeInteger(Object? value, String fieldName) {
  final result = _integer(value, fieldName);
  if (result < 0) {
    throw ApiContractException('Pagination $fieldName cannot be negative.');
  }
  return result;
}

int _integer(Object? value, String fieldName) {
  if (value is! num ||
      value.isNaN ||
      value.isInfinite ||
      value != value.roundToDouble()) {
    throw ApiContractException('Pagination $fieldName is not an integer.');
  }
  return value.toInt();
}

class ApiContractException implements Exception {
  const ApiContractException(this.message);

  final String message;

  @override
  String toString() => 'ApiContractException: $message';
}
