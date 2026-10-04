import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';

/// Tipos de notificación soportados por el sistema AppNotification.
enum NotificationType {
  error,
  success,
  info,
  warning,
  message;

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
        return AppIcons.error;
      case NotificationType.success:
        return AppIcons.success;
      case NotificationType.info:
        return AppIcons.info;
      case NotificationType.warning:
        return AppIcons.warning;
      case NotificationType.message:
        return AppIcons.message;
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
