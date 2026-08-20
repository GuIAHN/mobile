import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/network/api_endpoints.dart';
import 'package:guiautomotriz_mobile/core/network/dio_client.dart';
import 'package:guiautomotriz_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';

class _MockDioClient extends Mock implements DioClient {}

void main() {
  test('forgotPassword sends only the normalized public contract', () async {
    final client = _MockDioClient();
    final datasource = AuthRemoteDataSource(client);
    const payload = {'email': 'user@example.com'};

    when(
      () => client.post<Map<String, dynamic>>(
        ApiEndpoints.forgotPassword,
        data: payload,
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ApiEndpoints.forgotPassword),
        statusCode: 202,
        data: const {
          'message':
              'Si el correo está registrado, recibirás un código de verificación.',
        },
      ),
    );

    final message = await datasource.forgotPassword(
      email: 'user@example.com',
    );

    expect(message, contains('recibirás un código'));
    verify(
      () => client.post<Map<String, dynamic>>(
        ApiEndpoints.forgotPassword,
        data: payload,
      ),
    ).called(1);
    verifyNoMoreInteractions(client);
  });

  test('resetPassword sends email, six-digit code and new password', () async {
    final client = _MockDioClient();
    final datasource = AuthRemoteDataSource(client);
    const payload = {
      'email': 'user@example.com',
      'code': '123456',
      'newPassword': 'newpass1',
    };

    when(
      () => client.post<Map<String, dynamic>>(
        ApiEndpoints.resetPassword,
        data: payload,
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ApiEndpoints.resetPassword),
        statusCode: 200,
        data: const {'message': 'Contraseña actualizada exitosamente'},
      ),
    );

    final message = await datasource.resetPassword(
      email: 'user@example.com',
      code: '123456',
      newPassword: 'newpass1',
    );

    expect(message, 'Contraseña actualizada exitosamente');
    verify(
      () => client.post<Map<String, dynamic>>(
        ApiEndpoints.resetPassword,
        data: payload,
      ),
    ).called(1);
    verifyNoMoreInteractions(client);
  });

  test('changePassword uses the authenticated POST contract', () async {
    final client = _MockDioClient();
    final datasource = AuthRemoteDataSource(client);
    const payload = {
      'currentPassword': 'oldpass1',
      'newPassword': 'newpass1',
    };

    when(
      () => client.post<Map<String, dynamic>>(
        ApiEndpoints.changePassword,
        data: payload,
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ApiEndpoints.changePassword),
        statusCode: 200,
        data: const {'message': 'Contraseña actualizada exitosamente'},
      ),
    );

    await datasource.changePassword(
      currentPassword: 'oldpass1',
      newPassword: 'newpass1',
    );

    verify(
      () => client.post<Map<String, dynamic>>(
        ApiEndpoints.changePassword,
        data: payload,
      ),
    ).called(1);
    verifyNoMoreInteractions(client);
  });
}
