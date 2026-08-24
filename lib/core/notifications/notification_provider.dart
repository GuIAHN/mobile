import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_model.dart';
import 'notification_type.dart';

/// Máximo de notificaciones visibles simultáneamente en el host.
const int kMaxVisibleNotifications = 2;

// ── Provider ────────────────────────────────────────────────────────────────

/// Provider global de la cola de notificaciones activas.
///
/// Observado por [AppNotificationHost] para renderizar los toasts en pantalla.
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<NotificationModel>>(
  (ref) => NotificationNotifier(),
);

// ── Notifier ─────────────────────────────────────────────────────────────────

/// Gestiona la cola de notificaciones activas (FIFO, máx. [kMaxVisibleNotifications]).
class NotificationNotifier extends StateNotifier<List<NotificationModel>> {
  NotificationNotifier() : super([]);

  /// Agrega una notificación a la cola.
  ///
  /// Si ya hay [kMaxVisibleNotifications] notificaciones, descarta la más antigua.
  void show({
    required NotificationType type,
    required String message,
    String? title,
    Duration? duration,
    bool isDismissible = true,
    String? sourceId,
    String? destinationPath,
  }) {
    final notification = NotificationModel.create(
      type: type,
      message: message,
      title: title,
      duration: duration,
      isDismissible: isDismissible,
      sourceId: sourceId,
      destinationPath: destinationPath,
    );

    final current = List<NotificationModel>.from(state);
    if (current.length >= kMaxVisibleNotifications) {
      current.removeAt(0); // descarta la más antigua
    }
    state = [...current, notification];
  }

  /// Descarta la notificación con el [id] dado.
  void dismiss(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  /// Descarta todas las notificaciones activas.
  void dismissAll() {
    state = [];
  }
}

// ── Shorthand Service ─────────────────────────────────────────────────────────

/// API estática de conveniencia para lanzar notificaciones con una sola línea.
///
/// **Uso:**
/// ```dart
/// NotificationService.error(ref, 'No se pudo guardar.');
/// NotificationService.success(ref, '¡Vehículo guardado!', title: 'Listo');
/// ```
abstract class NotificationService {
  static void error(
    WidgetRef ref,
    String message, {
    String? title,
    Duration? duration,
    bool isDismissible = true,
  }) =>
      ref.read(notificationProvider.notifier).show(
            type: NotificationType.error,
            message: message,
            title: title,
            duration: duration,
            isDismissible: isDismissible,
          );

  static void success(
    WidgetRef ref,
    String message, {
    String? title,
    Duration? duration,
    bool isDismissible = true,
  }) =>
      ref.read(notificationProvider.notifier).show(
            type: NotificationType.success,
            message: message,
            title: title,
            duration: duration,
            isDismissible: isDismissible,
          );

  static void info(
    WidgetRef ref,
    String message, {
    String? title,
    Duration? duration,
    bool isDismissible = true,
  }) =>
      ref.read(notificationProvider.notifier).show(
            type: NotificationType.info,
            message: message,
            title: title,
            duration: duration,
            isDismissible: isDismissible,
          );

  static void warning(
    WidgetRef ref,
    String message, {
    String? title,
    Duration? duration,
    bool isDismissible = true,
  }) =>
      ref.read(notificationProvider.notifier).show(
            type: NotificationType.warning,
            message: message,
            title: title,
            duration: duration,
            isDismissible: isDismissible,
          );
}
