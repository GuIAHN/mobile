import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import 'api_endpoints.dart';
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

  DioMediaType _getMediaType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return DioMediaType('image', 'png');
      case 'webp':
        return DioMediaType('image', 'webp');
      case 'jpg':
      case 'jpeg':
      default:
        return DioMediaType('image', 'jpeg');
    }
  }

  Future<String> uploadRequestImage(String filePath, {Uint8List? bytes}) =>
      _uploadImage(
        filePath,
        endpoint: ApiEndpoints.requestImageUpload,
        bytes: bytes,
      );

  Future<String> uploadOfferImage(String filePath, {Uint8List? bytes}) =>
      _uploadImage(
        filePath,
        endpoint: ApiEndpoints.offerImageUpload,
        bytes: bytes,
      );

  Future<String> uploadAvatarImage(String filePath, {Uint8List? bytes}) =>
      _uploadImage(
        filePath,
        endpoint: ApiEndpoints.avatarImageUpload,
        bytes: bytes,
      );

  /// Subida multipart de una imagen a un endpoint definido por su acción.
  /// Retorna la URL pública de la imagen almacenada.
  /// Compatible tanto con Web (Chrome/Safari) como con Móvil (Android/iOS).
  Future<String> _uploadImage(
    String filePath, {
    Uint8List? bytes,
    required String endpoint,
  }) async {
    final rawFileName = filePath.split('/').last.split('\\').last;
    final String fileName = rawFileName.isEmpty || rawFileName.startsWith('blob:')
        ? 'image_${DateTime.now().millisecondsSinceEpoch}.jpg'
        : rawFileName;

    final mediaType = _getMediaType(fileName);
    final MultipartFile multipartFile;

    if (kIsWeb) {
      Uint8List fileBytes;
      if (bytes != null) {
        fileBytes = bytes;
      } else if (filePath.startsWith('blob:') || filePath.startsWith('http')) {
        final standaloneDio = Dio();
        final res = await standaloneDio.get<List<int>>(
          filePath,
          options: Options(responseType: ResponseType.bytes),
        );
        fileBytes = Uint8List.fromList(res.data!);
      } else {
        throw Exception('No se pudieron obtener los bytes de la imagen en Web');
      }
      multipartFile = MultipartFile.fromBytes(
        fileBytes,
        filename: fileName,
        contentType: mediaType,
      );
    } else {
      multipartFile = await MultipartFile.fromFile(
        filePath,
        filename: fileName,
        contentType: mediaType,
      );
    }


    final formData = FormData.fromMap({
      'file': multipartFile,
    });

    final response = await _dio.post(
      endpoint,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );

    final data = response.data;
    if (data is Map && data.containsKey('url')) {
      return data['url'] as String;
    }
    throw Exception('Error al subir imagen: la respuesta no contiene la URL');
  }
}

