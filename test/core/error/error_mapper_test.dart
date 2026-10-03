import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/error/error_mapper.dart';
import 'package:guiautomotriz_mobile/core/error/failures.dart';
import 'package:guiautomotriz_mobile/core/error/exceptions.dart';

void main() {
  test('explains a sold-request conflict from the backend envelope', () {
    final request = RequestOptions(path: '/offers');
    final failure = ErrorMapper.map(DioException.badResponse(
      statusCode: 409,
      requestOptions: request,
      response: Response(
        requestOptions: request,
        statusCode: 409,
        data: const {
          'message': 'Search request is not OPEN',
          'data': {'reason': 'SEARCH_REQUEST_SOLD'},
        },
      ),
    ));
    expect(failure.message, 'Esta solicitud ya fue vendida por otra tienda.');
    expect(failure.code, 409);
  });

  test('legacy closed-request conflicts do not claim a sale', () {
    final request = RequestOptions(path: '/offers');
    final failure = ErrorMapper.map(DioException.badResponse(
      statusCode: 409,
      requestOptions: request,
      response: Response(
        requestOptions: request,
        statusCode: 409,
        data: const {'message': 'Search request is not OPEN'},
      ),
    ));
    expect(failure.message, 'Esta solicitud ya no está disponible.');
    expect(failure, isA<RequestUnavailableFailure>());
  });

  test('keeps unrelated conflicts retryable instead of labelling them sold',
      () {
    final request = RequestOptions(path: '/offers');
    final failure = ErrorMapper.map(DioException.badResponse(
      statusCode: 409,
      requestOptions: request,
      response: Response(requestOptions: request, statusCode: 409, data: const {
        'message': 'An offer has already been submitted for this match'
      }),
    ));
    expect(failure, isNot(isA<RequestUnavailableFailure>()));
  });

  test('maps legacy custom server exceptions without claiming a sale', () {
    final failure = ErrorMapper.map(const ServerException(
        statusCode: 409, message: 'Search request is not OPEN'));
    expect(failure, isA<RequestUnavailableFailure>());
    expect(failure.message, 'Esta solicitud ya no está disponible.');
  });

  test('recognizes expiration from a top-level reason', () {
    final request = RequestOptions(path: '/offers');
    final failure = ErrorMapper.map(DioException.badResponse(
      statusCode: 409,
      requestOptions: request,
      response: Response(requestOptions: request, statusCode: 409, data: const {
        'reason': 'SEARCH_REQUEST_EXPIRED',
        'message': 'Search request is not OPEN'
      }),
    ));
    expect(failure.message, 'Esta solicitud ya expiró.');
  });

  test('a server outage with a sale reason does not prove unavailability', () {
    final request = RequestOptions(path: '/offers');
    final failure = ErrorMapper.map(DioException.badResponse(
      statusCode: 500,
      requestOptions: request,
      response: Response(requestOptions: request, statusCode: 500, data: const {
        'reason': 'SEARCH_REQUEST_SOLD',
        'message': 'Search request is not OPEN'
      }),
    ));
    expect(failure, isNot(isA<RequestUnavailableFailure>()));
  });

  test('maps backend password validation to actionable Spanish feedback', () {
    expect(
      ErrorMapper.parseErrorMessage(
        'password must be longer than or equal to 8 characters',
      ),
      'La contraseña no cumple los requisitos de seguridad.',
    );
  });

  test('does not blame the password when a legacy backend rejects payload', () {
    const response =
        'property payload should not exist, email must be an email, password must be longer than or equal to 6 characters, name should not be empty';

    expect(
      ErrorMapper.parseErrorMessage(response),
      'No pudimos procesar el registro con documentos. El servidor necesita actualizarse antes de intentarlo nuevamente.',
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

  test('translates backend already-registered conflicts', () {
    expect(
      ErrorMapper.parseErrorMessage('Email is already registered'),
      'El correo electrónico ya está registrado.',
    );
  });

  test('translates an invalid account-deletion password', () {
    expect(
      ErrorMapper.parseErrorMessage('Invalid credentials'),
      'La contraseña actual no es correcta.',
    );
  });

  test('explains which pending work blocks account deletion', () {
    expect(
      ErrorMapper.parseErrorMessage(
        'Cannot delete account with pending operations',
      ),
      'Completa tus compras, ventas o liquidaciones pendientes antes de eliminar la cuenta.',
    );
  });

  test('translates a restore request for a non-pending account', () {
    expect(
      ErrorMapper.parseErrorMessage(
        'Cannot restore: account is not pending deletion',
      ),
      'Esta cuenta ya no está pendiente de eliminación.',
    );
  });

  test(
      'translates the catch-all subcategory rejection instead of leaking '
      'backend English text', () {
    expect(
      ErrorMapper.parseErrorMessage(
        'Catch-all subcategories are derived from your selection and '
        'cannot be configured directly',
      ),
      'Vuelve a seleccionar las categorías de tu catálogo e inténtalo de nuevo.',
    );
  });
}
