import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor de logging para peticiones y respuestas HTTP.
/// Solo activo en entornos no productivos (ver [AppConfig.enableLogging]).
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('┌─────── 🌐 REQUEST ───────────────────────────────');
    debugPrint('│ ${options.method.toUpperCase()} ${options.uri}');
    debugPrint('│ Headers: ${options.headers}');
    if (options.data != null) {
      debugPrint('│ Body: ${options.data}');
    }
    if (options.queryParameters.isNotEmpty) {
      debugPrint('│ Query: ${options.queryParameters}');
    }
    debugPrint('└──────────────────────────────────────────────────');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('┌─────── ✅ RESPONSE ──────────────────────────────');
    debugPrint('│ ${response.statusCode} ${response.requestOptions.uri}');
    debugPrint('│ Data: ${response.data}');
    debugPrint('└──────────────────────────────────────────────────');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('┌─────── ❌ ERROR ─────────────────────────────────');
    debugPrint('│ ${err.type.name} ${err.requestOptions.uri}');
    debugPrint('│ Status: ${err.response?.statusCode}');
    debugPrint('│ Message: ${err.message}');
    if (err.response?.data != null) {
      debugPrint('│ Response: ${err.response?.data}');
    }
    debugPrint('└──────────────────────────────────────────────────');
    handler.next(err);
  }
}
