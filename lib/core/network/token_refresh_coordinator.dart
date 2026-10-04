import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import 'api_endpoints.dart';

final tokenRefreshCoordinatorProvider =
    Provider<TokenRefreshCoordinator>((ref) {
  final coordinator = TokenRefreshCoordinator(
    ref.watch(secureStorageProvider),
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

class SessionInvalidatedException implements Exception {
  const SessionInvalidatedException();
}

class TokenRefreshUnavailableException implements Exception {
  const TokenRefreshUnavailableException();
}

/// Owns refresh-token rotation for every transport. Calls are single-flight:
/// a simultaneous HTTP 401 and WebSocket expiry share one network request and
/// therefore cannot race refresh-token rotation.
class TokenRefreshCoordinator {
  TokenRefreshCoordinator(SecureStorage storage, {Dio? dio})
      : _storage = storage,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout:
                    const Duration(milliseconds: AppConfig.connectTimeoutMs),
                receiveTimeout:
                    const Duration(milliseconds: AppConfig.receiveTimeoutMs),
                sendTimeout:
                    const Duration(milliseconds: AppConfig.sendTimeoutMs),
                headers: const {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            );

  final SecureStorage _storage;
  final Dio _dio;
  final _sessionInvalidatedController = StreamController<void>.broadcast();
  Future<String>? _inFlight;
  bool _invalidated = false;

  Stream<void> get onSessionInvalidated => _sessionInvalidatedController.stream;

  Future<String> refreshAccessToken() {
    return _inFlight ??= _refresh().whenComplete(() => _inFlight = null);
  }

  Future<void> invalidateSession() => _invalidateSession();

  /// Re-arms invalidation notifications after login/session restoration. A
  /// second terminal failure must be observable even if no refresh happened
  /// between the two authenticated sessions.
  void markSessionActive() {
    _invalidated = false;
  }

  Future<String> _refresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _invalidateSession();
      throw const SessionInvalidatedException();
    }

    try {
      final response = await _dio.post<Object?>(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );
      final root = response.data;
      final body = root is Map && root['data'] is Map ? root['data'] : root;
      if (body is! Map) {
        await _invalidateSession();
        throw const SessionInvalidatedException();
      }

      final accessToken = body['accessToken'];
      final rotatedRefreshToken = body['refreshToken'];
      if (accessToken is! String || accessToken.isEmpty) {
        await _invalidateSession();
        throw const SessionInvalidatedException();
      }

      await _storage.saveToken(accessToken);
      if (rotatedRefreshToken is String && rotatedRefreshToken.isNotEmpty) {
        await _storage.saveRefreshToken(rotatedRefreshToken);
      }
      _invalidated = false;
      return accessToken;
    } on SessionInvalidatedException {
      rethrow;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 400 || status == 401 || status == 403) {
        await _invalidateSession();
        throw const SessionInvalidatedException();
      }
      throw const TokenRefreshUnavailableException();
    } catch (_) {
      throw const TokenRefreshUnavailableException();
    }
  }

  Future<void> _invalidateSession() async {
    await _storage.clearTokens();
    if (_invalidated) return;
    _invalidated = true;
    _sessionInvalidatedController.add(null);
  }

  void dispose() {
    _sessionInvalidatedController.close();
  }
}
