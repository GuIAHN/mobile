import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/network/interceptors/auth_interceptor.dart';
import 'package:guiautomotriz_mobile/core/services/socket_service.dart';
import 'package:guiautomotriz_mobile/core/storage/secure_storage.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements SecureStorage {}

class _MockSocketService extends Mock implements SocketService {}

class _RefreshSequenceAdapter implements HttpClientAdapter {
  var resourceRequests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('auth/refresh')) {
      return ResponseBody.fromString(
        jsonEncode({
          'accessToken': 'access-token-2',
          'refreshToken': 'refresh-token-2',
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    resourceRequests++;
    if (resourceRequests == 1) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Unauthorized'}),
        401,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'ok': true}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('rotating an HTTP token reconnects Socket.IO with fresh credentials',
      () async {
    final storage = _MockSecureStorage();
    final socket = _MockSocketService();
    when(() => storage.getToken()).thenAnswer((_) async => 'access-token-1');
    when(() => storage.getRefreshToken())
        .thenAnswer((_) async => 'refresh-token-1');
    when(() => storage.saveToken(any())).thenAnswer((_) async {});
    when(() => storage.saveRefreshToken(any())).thenAnswer((_) async {});
    when(() => storage.clearTokens()).thenAnswer((_) async {});
    when(() => socket.connect()).thenAnswer((_) async {});

    late Dio dio;
    final interceptorProvider = Provider<AuthInterceptor>((ref) {
      return AuthInterceptor(ref, dio);
    });
    final container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        socketServiceProvider.overrideWithValue(socket),
      ],
    );
    addTearDown(container.dispose);

    dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
    dio.httpClientAdapter = _RefreshSequenceAdapter();
    dio.interceptors.add(container.read(interceptorProvider));

    final response = await dio.get<Map<String, dynamic>>('resource');

    expect(response.data, {'ok': true});
    verify(() => storage.saveToken('access-token-2')).called(1);
    verify(() => storage.saveRefreshToken('refresh-token-2')).called(1);
    verify(() => socket.connect()).called(1);
  });
}
