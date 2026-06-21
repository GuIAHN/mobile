import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_provider.dart';
import 'app_notification_toast.dart';

/// Host del sistema de notificaciones AppNotification.
///
/// **Debe insertarse una única vez**, envolviendo [MaterialApp] en `app.dart`.
///
/// Observa el [notificationProvider] y renderiza los toasts activos apilados
/// en la parte inferior-central de la pantalla con un offset entre ellos.
///
/// ```dart
/// AppNotificationHost(
///   child: MaterialApp.router(...),
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
            bottom: 0,
            child: SafeArea(
              child: _NotificationStack(
                notifications: notifications,
                ref: ref,
              ),
            ),
          ),
      ],
    );
  }
}

/// Renderiza la pila de toasts con offset vertical entre sí.
class _NotificationStack extends StatelessWidget {
  final List notifications;
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
