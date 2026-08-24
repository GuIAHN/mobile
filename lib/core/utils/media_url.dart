import '../config/env.dart';

/// Convierte rutas de medios del backend en URLs alcanzables desde el equipo.
/// El servidor puede persistir URLs con localhost; en un teléfono ese host
/// apunta al propio dispositivo, por lo que se reemplaza por el host de la API.
String? resolveMediaUrl(String? rawUrl) {
  final value = rawUrl?.trim();
  if (value == null || value.isEmpty) return null;

  final apiUri = Uri.tryParse(Env.baseUrl);
  final mediaUri = Uri.tryParse(value);
  if (apiUri == null || mediaUri == null) return value;

  if (!mediaUri.hasScheme) {
    final path = value.startsWith('/') ? value : '/$value';
    return apiUri.replace(path: path, query: null, fragment: null).toString();
  }

  const loopbackHosts = {'localhost', '127.0.0.1', '0.0.0.0'};
  if (loopbackHosts.contains(mediaUri.host) && mediaUri.host != apiUri.host) {
    return apiUri
        .replace(
          path: mediaUri.path,
          query: mediaUri.hasQuery ? mediaUri.query : null,
          fragment: mediaUri.hasFragment ? mediaUri.fragment : null,
        )
        .toString();
  }

  return value;
}
