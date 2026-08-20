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
    final titulo = data['titulo']?.toString();

    ref.read(notificationProvider.notifier).show(
          type: _typeForTipo(tipo),
          title: titulo,
          message: cuerpo,
        );
  });

  ref.onDispose(sub.cancel);
});

/// Mapea el `tipo` de notificación del backend al tipo semántico del toast.
NotificationType _typeForTipo(String tipo) {
  switch (tipo) {
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
