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

  /// Temporary compatibility for legacy Sahala migration files. New
  /// repositories use the typed methods below.
  @Deprecated('Use the typed ApiClient methods instead.')
  Dio get dio => _dio;

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

  Future<ApiEnvelope<T>> _request<T>(
    Future<Response<Object?>> Function() request, {
    required ApiDataDecoder<T> decode,
  }) async {
    try {
      final response = await request();
      final payload = _asObjectMap(response.data);
      final envelope = ApiEnvelope<T>.fromJson(payload, decode);

      if (!envelope.success) {
        throw ApiFailure.unexpected(
          serverMessage: envelope.message.isEmpty ? null : envelope.message,
        );
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

  Options _requestOptions(bool requiresAuthentication) {
    return Options(extra: {_requiresAuthenticationKey: requiresAuthentication});
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
