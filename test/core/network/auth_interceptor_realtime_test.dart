import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/network/interceptors/auth_interceptor.dart';
import 'package:guiautomotriz_mobile/core/network/token_refresh_coordinator.dart';
import 'package:guiautomotriz_mobile/core/storage/secure_storage.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements SecureStorage {}

class _MockTokenRefreshCoordinator extends Mock
    implements TokenRefreshCoordinator {}

class _RefreshSequenceAdapter implements HttpClientAdapter {
  var resourceRequests = 0;
  final authorizationHeaders = <Object?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    resourceRequests++;
    authorizationHeaders.add(options.headers['Authorization']);
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
  test('HTTP 401 uses the shared refresh coordinator and retries once',
      () async {
    final storage = _MockSecureStorage();
    final coordinator = _MockTokenRefreshCoordinator();
    var accessToken = 'access-token-1';
    when(() => storage.getToken()).thenAnswer((_) async => accessToken);
    when(() => coordinator.refreshAccessToken()).thenAnswer((_) async {
      accessToken = 'access-token-2';
      return accessToken;
    });

    late Dio dio;
    final interceptorProvider = Provider<AuthInterceptor>((ref) {
      return AuthInterceptor(ref, dio);
    });
    final container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(storage),
        tokenRefreshCoordinatorProvider.overrideWithValue(coordinator),
      ],
    );
    addTearDown(container.dispose);

    dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
    final adapter = _RefreshSequenceAdapter();
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(container.read(interceptorProvider));

    final response = await dio.get<Map<String, dynamic>>('resource');

    expect(response.data, {'ok': true});
    verify(() => coordinator.refreshAccessToken()).called(1);
    expect(adapter.authorizationHeaders, [
      'Bearer access-token-1',
      'Bearer access-token-2',
    ]);
  });
}
