import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class NotificationVisualStyle {
  const NotificationVisualStyle({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;

  factory NotificationVisualStyle.forType(String type) {
    if (type == 'offer.cancelled') {
      return const NotificationVisualStyle(
        label: 'Compra cancelada',
        icon: Icons.block_rounded,
        foreground: AppColors.errorInk,
        background: AppColors.errorLight,
      );
    }
    if (type == 'search.no_store_available') {
      return const NotificationVisualStyle(
        label: 'Sin disponibilidad',
        icon: Icons.storefront_outlined,
        foreground: AppColors.warningInk,
        background: AppColors.warningLight,
      );
    }
    if (type.startsWith('offer.')) {
      return const NotificationVisualStyle(
        label: 'Oferta',
        icon: Icons.local_offer_outlined,
        foreground: AppColors.primaryInk,
        background: AppColors.primaryMuted,
      );
    }
    if (type.startsWith('message.')) {
      return const NotificationVisualStyle(
        label: 'Mensaje',
        icon: Icons.chat_bubble_outline_rounded,
        foreground: AppColors.info,
        background: AppColors.infoLight,
      );
    }
    if (type.startsWith('search.')) {
      return const NotificationVisualStyle(
        label: 'Solicitud',
        icon: Icons.manage_search_rounded,
        foreground: AppColors.celesteInk,
        background: AppColors.celesteMuted,
      );
    }
    if (type.startsWith('user.')) {
      return const NotificationVisualStyle(
        label: 'Cuenta',
        icon: Icons.account_circle_outlined,
        foreground: AppColors.successInk,
        background: AppColors.successLight,
      );
    }
    if (type.startsWith('settlement.')) {
      return const NotificationVisualStyle(
        label: 'Pago',
        icon: Icons.receipt_long_outlined,
        foreground: AppColors.warningInk,
        background: AppColors.warningLight,
      );
    }
    return const NotificationVisualStyle(
      label: 'Notificación',
      icon: Icons.notifications_none_rounded,
      foreground: AppColors.primaryInk,
      background: AppColors.primaryMuted,
    );
  }
}
