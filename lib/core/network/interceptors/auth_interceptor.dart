import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../storage/secure_storage.dart';
import '../api_endpoints.dart';

/// Interceptor de autenticación.
/// - Agrega el Bearer token a cada petición.
/// - Refresca el token automáticamente cuando recibe un 401.
class AuthInterceptor extends Interceptor {
  final Ref _ref;
  final Dio _dio;

  // Previene múltiples refreshes simultáneos.
  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingRequests = [];

  AuthInterceptor(this._ref, this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final storage = _ref.read(secureStorageProvider);
    final token = await storage.getToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Evitar bucle infinito: si el refresh mismo falla, propagar el error.
      if (err.requestOptions.path == ApiEndpoints.refreshToken) {
        return handler.next(err);
      }

      if (_isRefreshing) {
        // Encolar la petición para reintentarla cuando se refresque el token.
        _pendingRequests.add(_PendingRequest(err, handler));
        return;
      }

      _isRefreshing = true;

      try {
        final storage = _ref.read(secureStorageProvider);
        final refreshToken = await storage.getRefreshToken();

        if (refreshToken == null) {
          await storage.clearTokens();
          _rejectPendingRequests();
          return handler.next(err);
        }

        final response = await _dio.post<Map<String, dynamic>>(
          ApiEndpoints.refreshToken,
          data: {'refreshToken': refreshToken},
        );

        final newToken = response.data?['accessToken'] as String?;
        final newRefreshToken = response.data?['refreshToken'] as String?;

        if (newToken != null) {
          await storage.saveToken(newToken);
          if (newRefreshToken != null) {
            await storage.saveRefreshToken(newRefreshToken);
          }

          // Reintentar la petición original con el nuevo token.
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await _dio.fetch(err.requestOptions);
          handler.resolve(retryResponse);

          // Reintentar peticiones pendientes.
          for (final pending in _pendingRequests) {
            pending.err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            _dio.fetch(pending.err.requestOptions).then(
              (resp) => pending.handler.resolve(resp),
              onError: (dynamic error) {
                if (error is DioException) {
                  pending.handler.reject(error);
                } else {
                  pending.handler.reject(
                    DioException(
                      requestOptions: pending.err.requestOptions,
                      error: error,
                    ),
                  );
                }
              },
            ).ignore();
          }
          _pendingRequests.clear();
        } else {
          await storage.clearTokens();
          _rejectPendingRequests();
          handler.next(err);
        }
      } catch (e) {
        final storage = _ref.read(secureStorageProvider);
        await storage.clearTokens();
        _rejectPendingRequests();
        handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }

  void _rejectPendingRequests() {
    for (final pending in _pendingRequests) {
      pending.handler.reject(pending.err);
    }
    _pendingRequests.clear();
  }
}

class _PendingRequest {
  final DioException err;
  final ErrorInterceptorHandler handler;

  _PendingRequest(this.err, this.handler);
}
