import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/error/error_mapper.dart';
import 'package:guiautomotriz_mobile/core/error/failures.dart';

void main() {
  test('maps backend password validation to actionable Spanish feedback', () {
    expect(
      ErrorMapper.parseErrorMessage(
        'password must be longer than or equal to 8 characters',
      ),
      'La contraseña no cumple los requisitos de seguridad.',
    );
  });

  test('does not expose missing-token backend text to the user', () {
    final request = RequestOptions(path: '/reports/store/dashboard');
    final failure = ErrorMapper.map(
      DioException.badResponse(
        statusCode: 401,
        requestOptions: request,
        response: Response<Map<String, dynamic>>(
          requestOptions: request,
          statusCode: 401,
          data: const {'message': 'Missing authorization token'},
        ),
      ),
    );

    expect(failure, isA<UnauthorizedFailure>());
    expect(failure.message, contains('Inicia sesión'));
    expect(failure.message, isNot(contains('authorization token')));
  });
}
