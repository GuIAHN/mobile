import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_model.dart';
import '../../core/notifications/notification_provider.dart';
import 'app_notification_toast.dart';

/// Host del sistema de notificaciones AppNotification.
///
/// **Debe insertarse una única vez**, en el `builder` de [MaterialApp.router] en `app.dart`.
///
/// Observa el [notificationProvider] y renderiza los toasts activos apilados
/// en la parte superior de la pantalla, respetando el área segura.
///
/// ```dart
/// MaterialApp.router(
///   ...
///   builder: (context, child) => AppNotificationHost(
///     child: child ?? const SizedBox.shrink(),
///   ),
/// )
/// ```
class AppNotificationHost extends ConsumerWidget {
  final Widget child;

  const AppNotificationHost({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);

    return Stack(
      children: [
        child,
        if (notifications.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            top: 0,
            child: SafeArea(
              minimum: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _NotificationStack(
                    notifications: notifications,
                    ref: ref,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Renderiza la pila de toasts con offset vertical entre sí.
class _NotificationStack extends StatelessWidget {
  final List<NotificationModel> notifications;
  final WidgetRef ref;

  const _NotificationStack({
    required this.notifications,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: notifications.map((n) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppNotificationToast(
            key: ValueKey(n.id),
            notification: n,
            onDismissed: () {
              ref.read(notificationProvider.notifier).dismiss(n.id);
            },
          ),
        );
      }).toList(),
    );
  }
}
