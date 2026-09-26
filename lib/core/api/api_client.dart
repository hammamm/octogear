import 'package:dio/dio.dart';

import '../configuration/app_configuration.dart';
import '../service/app_logger.dart';
import 'api_envelope.dart';
import 'api_failure.dart';

typedef AccessTokenResolver = String? Function();
typedef ApiLocaleResolver = String Function();
typedef ApiDataDecoder<T> = T Function(Object? data);

/// The single HTTP boundary for OctoGear.
///
/// It centralizes base URL selection, timeouts, `Accept-Language`, and bearer
/// authentication. Repositories provide a typed decoder and never attach
/// headers directly.
class ApiClient {
  ApiClient({
    AppConfiguration? configuration,
    AccessTokenResolver? accessTokenResolver,
    ApiLocaleResolver? localeResolver,
    Dio? dio,
  }) : _accessTokenResolver = accessTokenResolver ?? _noAccessToken,
       _localeResolver = localeResolver ?? _arabicLocale,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: _baseUrlForDio(
                 (configuration ?? AppConfiguration.fromDartDefines())
                     .apiBaseUrl,
               ),
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 20),
               sendTimeout: const Duration(seconds: 20),
               headers: const {
                 Headers.acceptHeader: Headers.jsonContentType,
                 Headers.contentTypeHeader: Headers.jsonContentType,
               },
             ),
           ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers[Headers.acceptHeader] = Headers.jsonContentType;
          options.headers['Accept-Language'] = _localeResolver();

          if (options.extra[_requiresAuthenticationKey] == true) {
            final token = _accessTokenResolver();
            if (token != null && token.isNotEmpty) {
              options.headers[_authorizationHeader] = 'Bearer $token';
            }
          } else {
            options.headers.remove(_authorizationHeader);
          }

          handler.next(options);
        },
      ),
    );
    _dio.interceptors.add(AppLogInterceptor());
  }

  static const _requiresAuthenticationKey = 'octogear.requiresAuthentication';
  static const _authorizationHeader = 'Authorization';

  final Dio _dio;
  final AccessTokenResolver _accessTokenResolver;
  final ApiLocaleResolver _localeResolver;

  static String? _noAccessToken() => null;
  static String _arabicLocale() => 'ar';

  Future<ApiEnvelope<T>> get<T>(
    String path, {
    required ApiDataDecoder<T> decode,
    bool requiresAuthentication = false,
    Map<String, Object?>? queryParameters,
  }) {
    return _request(
      () => _dio.get<Object?>(
        _relativePath(path),
        queryParameters: queryParameters,
        options: _requestOptions(requiresAuthentication),
      ),
      decode: decode,
    );
  }

  Future<ApiEnvelope<T>> post<T>(
    String path, {
    required ApiDataDecoder<T> decode,
    Object? data,
    bool requiresAuthentication = false,
  }) {
    return _request(
      () => _dio.post<Object?>(
        _relativePath(path),
        data: data,
        options: _requestOptions(requiresAuthentication),
      ),
      decode: decode,
    );
  }

  /// Sends a typed multipart request while preserving the shared bearer token,
  /// locale header, timeouts, error mapping, and redacted request logging.
  ///
  /// Callers must create a fresh [FormData] instance for every attempt because
  /// multipart files are finalized after they are transmitted.
  Future<ApiEnvelope<T>> postMultipart<T>(
    String path, {
    required FormData data,
    required ApiDataDecoder<T> decode,
    bool requiresAuthentication = false,
    Map<String, String> headers = const {},
  }) {
    return _request(
      () => _dio.post<Object?>(
        _relativePath(path),
        data: data,
        options: _requestOptions(
          requiresAuthentication,
          headers: headers,
          contentType: Headers.multipartFormDataContentType,
        ),
      ),
      decode: decode,
    );
  }

  /// Resolves a relative API URL returned by Laravel against the configured
  /// base host without requiring a feature to duplicate environment logic.
  Uri resolveUri(String apiPath) {
    final candidate = Uri.tryParse(apiPath);
    if (candidate != null && candidate.hasScheme) return candidate;
    return Uri.parse(_dio.options.baseUrl).resolve(apiPath);
  }

  /// Resolves a private API-media URL only when it stays on this API origin.
  ///
  /// A bearer header must never be attached to an arbitrary URL returned by a
  /// malformed or compromised response. Feature DTOs should still require the
  /// documented API-relative path before reaching this boundary.
  Uri? resolveAuthenticatedApiUri(String apiPath) {
    final base = Uri.parse(_dio.options.baseUrl);
    final candidate = Uri.tryParse(apiPath);
    final resolved = candidate != null && candidate.hasScheme
        ? candidate
        : base.resolve(apiPath);

    if (resolved.scheme != base.scheme ||
        resolved.host != base.host ||
        resolved.port != base.port) {
      return null;
    }
    return resolved;
  }

  /// Headers for a secure non-Dio consumer such as Flutter's Image widget.
  /// The bearer value remains memory-only and must never be moved into a URL.
  Map<String, String> get authenticatedHeaders {
    final token = _accessTokenResolver();
    if (token == null || token.isEmpty) return const {};
    return {_authorizationHeader: 'Bearer $token'};
  }

  Future<ApiEnvelope<T>> _request<T>(
    Future<Response<Object?>> Function() request, {
    required ApiDataDecoder<T> decode,
  }) async {
    try {
      final response = await request();
      final payload = _asObjectMap(response.data);
      final envelope = ApiEnvelope<T>.fromJson(payload, decode);

      if (!envelope.success) {
        // A `success: false` payload without an HTTP failure status does not
        // establish that its message is safe to render to a customer.
        throw const ApiFailure.unexpected();
      }
      return envelope;
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    } on ApiFailure {
      rethrow;
    } on ApiContractException {
      throw const ApiFailure.unexpected();
    } catch (_) {
      throw const ApiFailure.unexpected();
    }
  }

  Options _requestOptions(
    bool requiresAuthentication, {
    Map<String, String> headers = const {},
    String? contentType,
  }) {
    return Options(
      extra: {_requiresAuthenticationKey: requiresAuthentication},
      headers: headers.isEmpty ? null : headers,
      contentType: contentType,
    );
  }

  /// Dio resolves a leading slash from the domain root and a base URL without
  /// a trailing slash as though `api` were a file. Normalize both once so the
  /// configured `.../api` base reliably produces `.../api/profile`.
  static String _baseUrlForDio(String apiBaseUrl) {
    return '${apiBaseUrl.replaceFirst(RegExp(r'/+$'), '')}/';
  }

  static String _relativePath(String path) {
    return path.replaceFirst(RegExp(r'^/+'), '');
  }

  Map<String, Object?> _asObjectMap(Object? value) {
    if (value is! Map) {
      throw const ApiContractException(
        'The response body is not a JSON object.',
      );
    }

    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw const ApiContractException('The response has a non-string key.');
      }
      result[entry.key as String] = entry.value;
    }
    return result;
  }
}
