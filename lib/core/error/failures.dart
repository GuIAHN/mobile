import 'package:equatable/equatable.dart';

/// Jerarquía de fallos del dominio.
/// Usado con `Either<Failure, T>` de dartz.
/// Las clases de Failure NO conocen Dio ni HTTP — son puro dominio.
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

// ── Fallos de red ─────────────────────────────────────────────────────────

/// No hay conexión a internet.
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Sin conexión a internet.'});
}

/// El servidor respondió con un error (4xx / 5xx).
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

/// Tiempo de espera agotado.
class TimeoutFailure extends Failure {
  const TimeoutFailure({super.message = 'Tiempo de espera agotado.'});
}

// ── Fallos de autenticación ───────────────────────────────────────────────

/// Token expirado o inválido (401).
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.message = 'Sesión expirada. Inicia sesión nuevamente.'});
}

/// Sin permisos para la acción (403).
class ForbiddenFailure extends Failure {
  const ForbiddenFailure({super.message = 'No tienes permisos para esta acción.'});
}

// ── Fallos de datos ───────────────────────────────────────────────────────

/// Recurso no encontrado (404).
class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message = 'Recurso no encontrado.'});
}

/// Error al parsear la respuesta JSON.
class ParseFailure extends Failure {
  const ParseFailure({super.message = 'Error al procesar la respuesta del servidor.'});
}

/// Error de validación (422).
class ValidationFailure extends Failure {
  final Map<String, List<String>>? errors;

  const ValidationFailure({
    super.message = 'Datos inválidos.',
    this.errors,
  });

  @override
  List<Object?> get props => [message, code, errors];
}

// ── Fallo genérico ────────────────────────────────────────────────────────

/// Cualquier error no categorizado.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({super.message = 'Ocurrió un error inesperado.'});
}

class SocialNotRegisteredFailure extends Failure {
  final String email;
  final String name;
  final String sub;

  const SocialNotRegisteredFailure({
    required this.email,
    required this.name,
    required this.sub,
    super.message = 'Usuario no registrado en el sistema.',
  });

  @override
  List<Object?> get props => [message, code, email, name, sub];
}
