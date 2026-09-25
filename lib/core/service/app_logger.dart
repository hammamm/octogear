import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Central application logging.
///
/// Debug builds write formatted logs to the console. Profile and release builds
/// send ordinary logs to Crashlytics and errors as non-fatal Crashlytics events.
class AppLogger {
  AppLogger._();

  static Future<void> initialize() async {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );
  }

  static void installErrorHandlers() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(
        error(
          details.exception,
          stackTrace: details.stack,
          reason: 'Flutter framework error',
          fatal: true,
        ),
      );
    };

    PlatformDispatcher.instance.onError = (error, stackTrace) {
      unawaited(
        AppLogger.error(
          error,
          stackTrace: stackTrace,
          reason: 'Uncaught asynchronous error',
          fatal: true,
        ),
      );
      return true;
    };
  }

  /// General-purpose diagnostic log. Production writes a Crashlytics breadcrumb.
  static Future<void> log(Object? message, {String category = 'APP'}) async {
    final text = '[${category.toUpperCase()}] $message';
    if (kDebugMode) {
      debugPrint(
        '\n╔════════════════ ✍️ $category LOG ════════════════\n'
        '$message\n'
        '╚══════════════════════════════════════════════',
      );
      return;
    }
    await FirebaseCrashlytics.instance.log(text);
  }

  /// Network-specific logging. Request values with common secret keys are masked.
  static Future<void> network(Object? message) =>
      log(_redact(message), category: 'NETWORK 📡');

  /// Reports an error. Production records a non-fatal Crashlytics event by default.
  ///
  /// Only call this for critical/unexpected failures - a defect, or
  /// something outside the app's control (network failure, unexpected
  /// server error, a parsing bug, ...) - the kind of thing that needs to be
  /// found and fixed. Do **not** call it for expected business-logic
  /// outcomes that are simply shown to the user as a message/alert (wrong
  /// OTP, invalid input the backend rejected with a reason, "no results
  /// found", etc.) - those aren't defects, and logging every one of them
  /// buries real incidents in Crashlytics noise.
  static Future<void> error(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    bool fatal = false,
  }) async {
    final detail = reason == null ? '$error' : '$reason\n$error';
    if (kDebugMode) {
      debugPrint(
        '\n╔════════════════ ❌ ERROR ════════════════\n'
        '$detail\n'
        '${stackTrace ?? ''}'
        '╚══════════════════════════════════════════',
      );
      return;
    }
    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }

  static Object? _redact(Object? value) {
    if (value is Map) {
      return value.map((key, item) {
        final keyText = key.toString().toLowerCase();
        final isSecret = [
          'authorization',
          'token',
          'otp',
          'password',
          'secret',
          'mobile',
          'phone',
          'email',
          'full_name',
          'name',
          'national_id',
        ].any(keyText.contains);
        return MapEntry(key, isSecret ? '***' : _redact(item));
      });
    }
    if (value is Iterable) return value.map(_redact).toList();
    return value;
  }
}

/// Replaces Dio's verbose [LogInterceptor] with consistent, redacted app logs.
class AppLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    unawaited(
      AppLogger.network({
        'event': 'REQUEST',
        'method': options.method,
        'url': options.uri.replace(query: null).toString(),
        'headers': options.headers,
        'body': options.data,
      }),
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    unawaited(
      AppLogger.network({
        'event': 'RESPONSE',
        'statusCode': response.statusCode,
        'method': response.requestOptions.method,
        'url': response.requestOptions.uri.replace(query: null).toString(),
        'body': response.data,
      }),
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    unawaited(
      AppLogger.error(
        err,
        stackTrace: err.stackTrace,
        reason:
            'Network ${err.requestOptions.method} ${err.requestOptions.uri}',
      ),
    );
    handler.next(err);
  }
}

/// Logs navigation as the Flutter equivalent of view-controller open/close logs.
class AppRouteObserver extends NavigatorObserver {
  String _routeName(Route<dynamic> route) =>
      route.settings.name ?? route.runtimeType.toString();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    unawaited(
      AppLogger.log('${_routeName(route)} OPENED >>>', category: 'VIEW'),
    );
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    unawaited(
      AppLogger.log('${_routeName(route)} CLOSED <<<', category: 'VIEW'),
    );
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) {
      unawaited(
        AppLogger.log('${_routeName(oldRoute)} CLOSED <<<', category: 'VIEW'),
      );
    }
    if (newRoute != null) {
      unawaited(
        AppLogger.log('${_routeName(newRoute)} OPENED >>>', category: 'VIEW'),
      );
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    unawaited(
      AppLogger.log('${_routeName(route)} CLOSED <<<', category: 'VIEW'),
    );
    super.didRemove(route, previousRoute);
  }
}
