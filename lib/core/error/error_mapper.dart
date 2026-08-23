import 'package:dio/dio.dart';
import 'exceptions.dart';
import 'failures.dart';

/// Convierte cualquier excepción capturada en la capa data a un [Failure] de dominio.
/// Punto central de traducción: data → domain.
class ErrorMapper {
  ErrorMapper._();

  /// Mapea una excepción a su [Failure] correspondiente.
  static Failure map(Object e) {
    if (e is SocialNotRegisteredException) {
      return SocialNotRegisteredFailure(
        email: e.email,
        name: e.name,
        sub: e.sub,
      );
    }
    if (e is UnauthorizedException) {
      return const UnauthorizedFailure();
    }
    if (e is ForbiddenException) {
      return const ForbiddenFailure();
    }
    if (e is NotFoundException) {
      return const NotFoundFailure();
    }
    if (e is ParseException) {
      return const ParseFailure();
    }
    if (e is ValidationException) {
      return ValidationFailure(message: e.message, errors: e.errors);
    }
    if (e is ServerException) {
      final parsedMessage = parseErrorMessage(e.message);
      if (e.statusCode >= 500) {
        if (parsedMessage != e.message) {
          return ServerFailure(message: parsedMessage, code: e.statusCode);
        }
        return ServerFailure(
            message: 'El sistema está en mantenimiento. Inténtalo más tarde.',
            code: e.statusCode);
      }
      return ServerFailure(message: parsedMessage, code: e.statusCode);
    }
    if (e is NetworkException) {
      return const NetworkFailure(
          message: 'El sistema está en mantenimiento. Inténtalo más tarde.');
    }
    if (e is TimeoutException) {
      return const TimeoutFailure(
          message: 'El sistema está en mantenimiento. Inténtalo más tarde.');
    }

    // ── Manejo de errores Dio crudos (por si un repositorio no usa las excepciones custom) ─
    if (e is DioException) {
      return _mapDioException(e);
    }

    return const UnexpectedFailure();
  }

  static Failure _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const TimeoutFailure(
            message: 'El sistema está en mantenimiento. Inténtalo más tarde.');
      case DioExceptionType.connectionError:
        return const NetworkFailure(
            message: 'El sistema está en mantenimiento. Inténtalo más tarde.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        final serverMessage = _extractMessage(e.response?.data);
        final rawMessage = serverMessage ?? e.message ?? 'Error del servidor.';
        final message = parseErrorMessage(rawMessage);

        if (statusCode >= 500) {
          if (message != rawMessage) {
            return ServerFailure(message: message, code: statusCode);
          }
          return ServerFailure(
              message: 'El sistema está en mantenimiento. Inténtalo más tarde.',
              code: statusCode);
        }
        switch (statusCode) {
          case 401:
            return UnauthorizedFailure(
                message: serverMessage == null
                    ? 'Sesión expirada. Inicia sesión nuevamente.'
                    : message);
          case 403:
            return ForbiddenFailure(
                message:
                    serverMessage ?? 'No tienes permisos para esta acción.');
          case 404:
            return NotFoundFailure(
                message: serverMessage ?? 'Recurso no encontrado.');
          case 400:
          case 422:
            return ValidationFailure(message: message);
          default:
            return ServerFailure(message: message, code: statusCode);
        }
      case DioExceptionType.unknown:
        if (e.message?.contains('SocketException') == true ||
            e.error?.toString().contains('SocketException') == true) {
          return const NetworkFailure(
              message:
                  'El sistema está en mantenimiento. Inténtalo más tarde.');
        }
        return const UnexpectedFailure();
      default:
        return const UnexpectedFailure();
    }
  }

  /// Analiza los detalles del mensaje de error del backend/BD para retornar algo amigable en español.
  static String parseErrorMessage(String originalMessage) {
    final lower = originalMessage.toLowerCase();

    if (lower.contains('missing authorization token')) {
      return 'No pudimos validar tu sesión. Inicia sesión e inténtalo nuevamente.';
    }

    final rejectsMultipartPayload =
        lower.contains('property payload should not exist');
    final reportsSeveralMissingRegistrationFields =
        lower.contains('password') &&
            lower.contains('email') &&
            (lower.contains('name') ||
                lower.contains('address') ||
                lower.contains('categories'));
    if (rejectsMultipartPayload || reportsSeveralMissingRegistrationFields) {
      return 'No pudimos procesar el registro con documentos. El servidor necesita actualizarse antes de intentarlo nuevamente.';
    }

    if (lower.contains('password')) {
      if (lower.contains('at least') ||
          lower.contains('minimum') ||
          lower.contains('longer than') ||
          lower.contains('weak')) {
        return 'La contraseña no cumple los requisitos de seguridad.';
      }
      if (lower.contains('match')) {
        return 'Las contraseñas no coinciden.';
      }
    }

    if ((lower.contains('phone') || lower.contains('telefono')) &&
        (lower.contains('invalid') ||
            lower.contains('must be') ||
            lower.contains('format'))) {
      return 'El número de teléfono no tiene un formato válido.';
    }

    if (lower.contains('email') &&
        (lower.contains('invalid') ||
            lower.contains('must be') ||
            lower.contains('format'))) {
      return 'El correo electrónico no tiene un formato válido.';
    }

    // Restricciones de unicidad (Unique constraint failed)
    if (lower.contains('unique constraint failed') ||
        lower.contains('already exists') ||
        lower.contains('duplicate key')) {
      if (lower.contains('number') ||
          lower.contains('telefono') ||
          lower.contains('phone')) {
        return 'El número de teléfono ya está registrado por otro usuario o comercio.';
      }
      if (lower.contains('email') || lower.contains('correo')) {
        return 'El correo electrónico ya está registrado.';
      }
      if (lower.contains('rif')) {
        return 'El RIF ya está registrado.';
      }
      if (lower.contains('identification') ||
          lower.contains('cedula') ||
          lower.contains('cédula')) {
        return 'El documento de identidad ya está registrado.';
      }
    }

    // Errores de Prisma / base de datos crudos sobre teléfonos o campos específicos
    if (lower.contains('tx.phone.create') ||
        lower.contains('prisma') ||
        lower.contains('database') ||
        lower.contains('sql')) {
      if (lower.contains('phone') || lower.contains('number')) {
        return 'El número de teléfono ya está registrado por otro usuario o comercio.';
      }
      return 'Error de base de datos en el servidor. Por favor, verifica los datos ingresados.';
    }

    return originalMessage;
  }

  /// Extracts the error message from various API response formats.
  static String? _extractMessage(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is Map<String, dynamic>) {
      final msg = data['message'];
      if (msg is List) {
        return msg.join(', ');
      }
      if (msg is String) {
        return msg;
      }
      return data['error'] as String? ?? data['detail'] as String?;
    }
    return null;
  }
}
