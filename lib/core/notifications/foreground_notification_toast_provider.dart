import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/socket_service.dart';
import 'notification_provider.dart';
import 'notification_type.dart';

/// Escucha global del evento `notification.new` (WebSocket) para mostrar el
/// toast interno [AppNotificationToast] cuando la app está en foreground.
final foregroundNotificationToastProvider = Provider<void>((ref) {
  final socketService = ref.watch(socketServiceProvider);

  final sub = socketService.onNotification.listen((data) {
    final cuerpo = data['cuerpo']?.toString() ?? '';
    if (cuerpo.isEmpty) return;

    final tipo = data['tipo']?.toString() ?? '';
    var titulo = data['titulo']?.toString();
    var mensaje = cuerpo;

    // Para mensajes, el backend envía "Remitente: vista previa". Separarlo
    // crea una jerarquía natural (persona + mensaje) sin repetir el genérico
    // "Nuevo mensaje" dentro de una tarjeta ya identificada por su icono.
    if (tipo == 'message.new') {
      final separator = cuerpo.indexOf(':');
      if (separator > 0 && separator < cuerpo.length - 1) {
        titulo = cuerpo.substring(0, separator).trim();
        mensaje = cuerpo.substring(separator + 1).trim();
      }
    }

    ref.read(notificationProvider.notifier).show(
          type: _typeForTipo(tipo),
          title: titulo,
          message: mensaje,
        );
  });

  ref.onDispose(sub.cancel);
});

/// Mapea el `tipo` de notificación del backend al tipo semántico del toast.
NotificationType _typeForTipo(String tipo) {
  switch (tipo) {
    case 'message.new':
      return NotificationType.message;
    case 'user.rejected':
    case 'settlement.rejected':
      return NotificationType.error;
    case 'user.approved':
    case 'settlement.approved':
      return NotificationType.success;
    default:
      return NotificationType.info;
  }
}
