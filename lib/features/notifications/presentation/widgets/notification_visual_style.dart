import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';

class NotificationVisualStyle {
  const NotificationVisualStyle({
    required this.label,
    required this.icon,
    required this.foreground,
  });

  final String label;
  final IconData icon;
  final Color foreground;

  factory NotificationVisualStyle.forType(String type) {
    if (type == 'offer.cancelled') {
      return const NotificationVisualStyle(
        label: 'Compra cancelada',
        icon: AppIcons.cancellation,
        foreground: AppColors.errorInk,
      );
    }
    if (type == 'search.no_store_available') {
      return const NotificationVisualStyle(
        label: 'Sin disponibilidad',
        icon: AppIcons.store,
        foreground: AppColors.warningInk,
      );
    }
    if (type.startsWith('offer.')) {
      return const NotificationVisualStyle(
        label: 'Oferta',
        icon: AppIcons.offer,
        foreground: AppColors.primaryInk,
      );
    }
    if (type.startsWith('message.')) {
      return const NotificationVisualStyle(
        label: 'Mensaje',
        icon: AppIcons.message,
        foreground: AppColors.info,
      );
    }
    if (type.startsWith('search.')) {
      return const NotificationVisualStyle(
        label: 'Solicitud',
        icon: AppIcons.search,
        foreground: AppColors.celesteInk,
      );
    }
    if (type.startsWith('user.')) {
      return const NotificationVisualStyle(
        label: 'Cuenta',
        icon: AppIcons.account,
        foreground: AppColors.successInk,
      );
    }
    if (type.startsWith('settlement.')) {
      return const NotificationVisualStyle(
        label: 'Pago',
        icon: AppIcons.receipt,
        foreground: AppColors.warningInk,
      );
    }
    return const NotificationVisualStyle(
      label: 'Notificación',
      icon: AppIcons.notification,
      foreground: AppColors.primaryInk,
    );
  }
}
