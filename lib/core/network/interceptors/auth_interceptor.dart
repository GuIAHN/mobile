import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../storage/secure_storage.dart';
import '../api_endpoints.dart';
import '../token_refresh_coordinator.dart';

/// Adds the access token and retries a 401 after the shared single-flight
/// refresh coordinator rotates credentials. WebSocket and HTTP refreshes use
/// the same coordinator, so they cannot invalidate each other's refresh token.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._ref, this._dio);

  final Ref _ref;
  final Dio _dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _ref.read(secureStorageProvider).getToken();
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
    if (err.response?.statusCode == 404 && _isMissingUser(err)) {
      await _ref.read(tokenRefreshCoordinatorProvider).invalidateSession();
      return handler.next(err);
    }
    if (err.response?.statusCode != 401 ||
        _isAuthenticationEndpoint(err.requestOptions.path)) {
      return handler.next(err);
    }

    try {
      final accessToken =
          await _ref.read(tokenRefreshCoordinatorProvider).refreshAccessToken();
      err.requestOptions.headers['Authorization'] = 'Bearer $accessToken';
      handler.resolve(await _dio.fetch(err.requestOptions));
    } on SessionInvalidatedException {
      handler.next(err);
    } on TokenRefreshUnavailableException {
      // Preserve the original response. A transient refresh outage must not
      // erase a valid session; the next request/socket retry can recover.
      handler.next(err);
    }
  }

  bool _isAuthenticationEndpoint(String path) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return {
      ApiEndpoints.login,
      ApiEndpoints.socialLogin,
      ApiEndpoints.register,
      ApiEndpoints.refreshToken,
      ApiEndpoints.changePassword,
    }.contains(normalized);
  }

  bool _isMissingUser(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'];
      return message == 'User not found' ||
          (message is List && message.contains('User not found'));
    }
    return responseData is String && responseData.contains('User not found');
  }
}
