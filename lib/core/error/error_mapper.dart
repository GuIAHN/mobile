import 'package:dio/dio.dart';
import 'exceptions.dart';
import 'failures.dart';

/// Convierte cualquier excepción capturada en la capa data a un [Failure] de dominio.
/// Punto central de traducción: data → domain.
class ErrorMapper {
  ErrorMapper._();

  /// Mapea una excepción a su [Failure] correspondiente.
  static Failure map(Object e) {
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
      return ServerFailure(message: e.message, code: e.statusCode);
    }
    if (e is NetworkException) {
      return NetworkFailure(message: e.message);
    }
    if (e is TimeoutException) {
      return TimeoutFailure(message: e.message);
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
        return const TimeoutFailure();
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        final message = _extractMessage(e.response?.data) ??
            e.message ??
            'Error del servidor.';
        switch (statusCode) {
          case 401:
            return const UnauthorizedFailure();
          case 403:
            return const ForbiddenFailure();
          case 404:
            return const NotFoundFailure();
          case 400:
          case 422:
            return ValidationFailure(message: message);
          default:
            return ServerFailure(message: message, code: statusCode);
        }
      default:
        return const UnexpectedFailure();
    }
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
      return data['error'] as String? ??
          data['detail'] as String?;
    }
    return null;
  }
}
