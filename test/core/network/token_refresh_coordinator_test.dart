import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/network/token_refresh_coordinator.dart';
import 'package:guiautomotriz_mobile/core/storage/secure_storage.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements SecureStorage {}

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockSecureStorage storage;
  late _MockDio dio;
  late TokenRefreshCoordinator coordinator;

  setUp(() {
    storage = _MockSecureStorage();
    dio = _MockDio();
    coordinator = TokenRefreshCoordinator(storage, dio: dio);
    when(() => storage.getRefreshToken())
        .thenAnswer((_) async => 'refresh-old');
    when(() => storage.saveToken(any())).thenAnswer((_) async {});
    when(() => storage.saveRefreshToken(any())).thenAnswer((_) async {});
    when(() => storage.clearTokens()).thenAnswer((_) async {});
  });

  tearDown(() => coordinator.dispose());

  test('coalesces simultaneous refreshes and stores rotated credentials',
      () async {
    final response = Completer<Response<Object?>>();
    when(
      () => dio.post<Object?>(
        any(),
        data: any(named: 'data'),
      ),
    ).thenAnswer((_) => response.future);

    final first = coordinator.refreshAccessToken();
    final second = coordinator.refreshAccessToken();
    response.complete(
      Response<Object?>(
        requestOptions: RequestOptions(path: '/auth/refresh'),
        statusCode: 201,
        data: {
          'data': {
            'accessToken': 'access-new',
            'refreshToken': 'refresh-new',
          },
        },
      ),
    );

    await expectLater(first, completion('access-new'));
    await expectLater(second, completion('access-new'));
    verify(
      () => dio.post<Object?>(
        any(),
        data: any(named: 'data'),
      ),
    ).called(1);
    verify(() => storage.saveToken('access-new')).called(1);
    verify(() => storage.saveRefreshToken('refresh-new')).called(1);
  });

  test('invalidates the session for a terminal refresh rejection', () async {
    when(
      () => dio.post<Object?>(
        any(),
        data: any(named: 'data'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/auth/refresh'),
        response: Response<Object?>(
          requestOptions: RequestOptions(path: '/auth/refresh'),
          statusCode: 401,
        ),
      ),
    );
    final invalidated = coordinator.onSessionInvalidated.first;

    await expectLater(
      coordinator.refreshAccessToken(),
      throwsA(isA<SessionInvalidatedException>()),
    );
    await invalidated;
    verify(() => storage.clearTokens()).called(1);
  });

  test('preserves credentials for a transient refresh outage', () async {
    when(
      () => dio.post<Object?>(
        any(),
        data: any(named: 'data'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/auth/refresh'),
        type: DioExceptionType.connectionError,
      ),
    );

    await expectLater(
      coordinator.refreshAccessToken(),
      throwsA(isA<TokenRefreshUnavailableException>()),
    );
    verifyNever(() => storage.clearTokens());
  });

  test('emits a new invalidation after a successful relogin rearms it',
      () async {
    var invalidations = 0;
    final subscription = coordinator.onSessionInvalidated.listen((_) {
      invalidations += 1;
    });

    await coordinator.invalidateSession();
    coordinator.markSessionActive();
    await coordinator.invalidateSession();
    await pumpEventQueue();

    expect(invalidations, 2);
    verify(() => storage.clearTokens()).called(2);
    await subscription.cancel();
  });
}
