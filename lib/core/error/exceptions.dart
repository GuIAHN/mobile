/// Excepciones de la capa de datos (conocen Dio, HTTP, JSON).
/// Son capturadas en los repositorios y mapeadas a [Failure].
/// NO deben salir de la capa data.

class ServerException implements Exception {
  final String message;
  final int statusCode;

  const ServerException({required this.message, required this.statusCode});

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({this.message = 'Sin conexión a internet.'});

  @override
  String toString() => 'NetworkException: $message';
}

class TimeoutException implements Exception {
  final String message;

  const TimeoutException({this.message = 'Tiempo de espera agotado.'});

  @override
  String toString() => 'TimeoutException: $message';
}

class UnauthorizedException implements Exception {
  final String message;

  const UnauthorizedException({this.message = 'No autorizado.'});

  @override
  String toString() => 'UnauthorizedException: $message';
}

class ForbiddenException implements Exception {
  final String message;

  const ForbiddenException({this.message = 'Acceso prohibido.'});

  @override
  String toString() => 'ForbiddenException: $message';
}

class NotFoundException implements Exception {
  final String message;

  const NotFoundException({this.message = 'Recurso no encontrado.'});

  @override
  String toString() => 'NotFoundException: $message';
}

class ParseException implements Exception {
  final String message;

  const ParseException({this.message = 'Error al parsear la respuesta.'});

  @override
  String toString() => 'ParseException: $message';
}

class ValidationException implements Exception {
  final String message;
  final Map<String, List<String>>? errors;

  const ValidationException({
    this.message = 'Datos inválidos.',
    this.errors,
  });

  @override
  String toString() => 'ValidationException: $message';
}

class SocialNotRegisteredException implements Exception {
  final String email;
  final String name;
  final String sub;

  const SocialNotRegisteredException({
    required this.email,
    required this.name,
    required this.sub,
  });

  @override
  String toString() => 'SocialNotRegisteredException: $email ($name)';
}
