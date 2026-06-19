import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/response_unwrap_interceptor.dart';

/// Global provider for the configured Dio client.
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(ref);
});

/// Centralized HTTP client based on Dio.
/// Configures timeouts, base headers, and interceptors.
class DioClient {
  final Ref _ref;
  late final Dio _dio;

  DioClient(this._ref) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: Duration(milliseconds: AppConfig.connectTimeoutMs),
        receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeoutMs),
        sendTimeout: Duration(milliseconds: AppConfig.sendTimeoutMs),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _addInterceptors();
  }

  void _addInterceptors() {
    _dio.interceptors.add(ResponseUnwrapInterceptor());
    if (AppConfig.enableLogging) {
      _dio.interceptors.add(LoggingInterceptor());
    }
    _dio.interceptors.add(AuthInterceptor(_ref, _dio));
  }

  /// Dio instance for direct use in data sources.
  Dio get dio => _dio;

  // ── Convenience methods ──────────────────────────────────────────────

  String _cleanPath(String path) => path.startsWith('/') ? path.substring(1) : path;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.get<T>(_cleanPath(path), queryParameters: queryParameters, options: options);

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.post<T>(_cleanPath(path), data: data, queryParameters: queryParameters, options: options);

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.put<T>(_cleanPath(path), data: data, queryParameters: queryParameters, options: options);

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.patch<T>(_cleanPath(path), data: data, queryParameters: queryParameters, options: options);

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.delete<T>(_cleanPath(path), data: data, queryParameters: queryParameters, options: options);
}
