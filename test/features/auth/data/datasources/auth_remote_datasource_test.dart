import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/network/api_endpoints.dart';
import 'package:guiautomotriz_mobile/core/network/dio_client.dart';
import 'package:guiautomotriz_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/entities/store_coverage_config.dart';
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

  test('updateProfile sends the location contract to users/me', () async {
    final client = _MockDioClient();
    final datasource = AuthRemoteDataSource(client);
    const payload = {
      'location': {
        'lat': 14.0723,
        'lon': -87.1921,
      },
    };

    when(
      () => client.patch<Map<String, dynamic>>(
        ApiEndpoints.me,
        data: payload,
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ApiEndpoints.me),
        statusCode: 200,
        data: const {
          'id': 'store-1',
          'email': 'store@example.com',
          'name': 'Repuestos Centro',
          'userType': 'STORE',
        },
      ),
    );

    final user = await datasource.updateProfile(
      latitude: 14.0723,
      longitude: -87.1921,
    );

    expect(user.id, 'store-1');
    verify(
      () => client.patch<Map<String, dynamic>>(
        ApiEndpoints.me,
        data: payload,
      ),
    ).called(1);
    verifyNoMoreInteractions(client);
  });

  test('registerStore omits the removed category startingPrice field',
      () async {
    final client = _MockDioClient();
    final datasource = AuthRemoteDataSource(client);
    final tempDir = await Directory.systemTemp.createTemp('store-kyc-test-');
    addTearDown(() => tempDir.delete(recursive: true));
    final rifPhoto = File('${tempDir.path}/rif.jpg');
    final registryPhoto = File('${tempDir.path}/registry.jpg');
    await rifPhoto.writeAsBytes(const [1, 2, 3]);
    await registryPhoto.writeAsBytes(const [4, 5, 6]);

    when(
      () => client.post<Map<String, dynamic>>(
        'stores/register',
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: 'stores/register'),
        statusCode: 201,
        data: const {
          'id': 'store-user-id',
          'email': 'store@example.com',
        },
      ),
    );

    await datasource.registerStore(
      email: 'store@example.com',
      password: 'Lego1234!',
      name: 'Repuestos Centro',
      phone: '99999999',
      latitude: 10.4806,
      longitude: -66.9036,
      address: 'Tegucigalpa',
      rif: 'J123456789',
      coverage: const StoreCoverageConfig(
        servesAllBrands: false,
        subcategoryIds: ['9b80f867-9dae-4d0f-b019-831d81ff60b0'],
        brandIds: ['bd8d35f4-3f99-4d23-a7ad-314a5547abf4'],
        sparePartsTypes: ['ORIGINAL'],
      ),
      hasDelivery: true,
      acceptedTerms: true,
      rifPhotoPath: rifPhoto.path,
      mercantilRegistryPath: registryPhoto.path,
    );

    final formData = verify(
      () => client.post<Map<String, dynamic>>(
        'stores/register',
        data: captureAny(named: 'data'),
        options: any(named: 'options'),
      ),
    ).captured.single as FormData;
    final payload = jsonDecode(
      formData.fields.singleWhere((field) => field.key == 'payload').value,
    ) as Map<String, dynamic>;
    expect(payload['coverage'], {
      'servesAllBrands': false,
      'brandIds': ['bd8d35f4-3f99-4d23-a7ad-314a5547abf4'],
      'sparePartsTypes': ['ORIGINAL'],
      'subcategoryIds': ['9b80f867-9dae-4d0f-b019-831d81ff60b0'],
    });
    expect(payload, isNot(contains('categories')));
    expect(payload['hasDelivery'], isTrue);
    expect(payload['acceptedTerms'], isTrue);
    expect(payload['password'], 'Lego1234!');
    expect(formData.files.map((entry) => entry.key),
        containsAll(['rifPhoto', 'mercantilRegistry']));
    verifyNoMoreInteractions(client);
  });
}
