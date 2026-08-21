import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Tipos de notificación soportados por el sistema AppNotification.
enum NotificationType {
  error,
  success,
  info,
  warning,
  message;

  /// Color de fondo semántico (suave) de la notificación.
  Color get backgroundColor {
    switch (this) {
      case NotificationType.error:
        return AppColors.errorLight;
      case NotificationType.success:
        return AppColors.successLight;
      case NotificationType.info:
        return AppColors.infoLight;
      case NotificationType.warning:
        return AppColors.warningLight;
      case NotificationType.message:
        return AppColors.primaryMuted;
    }
  }

  /// Color del acento (borde, icono, progress bar).
  Color get accentColor {
    switch (this) {
      case NotificationType.error:
        return AppColors.error;
      case NotificationType.success:
        return AppColors.success;
      case NotificationType.info:
        return AppColors.info;
      case NotificationType.warning:
        return AppColors.warning;
      case NotificationType.message:
        return AppColors.primary;
    }
  }

  /// Icono representativo del tipo.
  IconData get icon {
    switch (this) {
      case NotificationType.error:
        return Icons.cancel_rounded;
      case NotificationType.success:
        return Icons.check_circle_rounded;
      case NotificationType.info:
        return Icons.info_rounded;
      case NotificationType.warning:
        return Icons.warning_amber_rounded;
      case NotificationType.message:
        return Icons.chat_bubble_rounded;
    }
  }

  /// Duración por defecto de la notificación antes de autodescartarse.
  Duration get defaultDuration {
    switch (this) {
      case NotificationType.error:
        return const Duration(seconds: 5);
      case NotificationType.success:
        return const Duration(seconds: 3);
      case NotificationType.info:
      case NotificationType.warning:
      case NotificationType.message:
        return const Duration(seconds: 4);
    }
  }

  /// Etiqueta de accesibilidad del tipo.
  String get label {
    switch (this) {
      case NotificationType.error:
        return 'Error';
      case NotificationType.success:
        return 'Éxito';
      case NotificationType.info:
        return 'Información';
      case NotificationType.warning:
        return 'Advertencia';
      case NotificationType.message:
        return 'Nuevo mensaje';
    }
  }
}
