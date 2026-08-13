import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

abstract class AppTokens {
  // Colores
  static const bg = Color(0xFFFAFAFA);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE5E7EB);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const accent = AppColors.primary;
  static const accentSoft = AppColors.primaryMuted;
  static const accentDark = AppColors.primaryDark;
  static const green = Color(0xFF16A34A);
  static const trackBg = Color(0xFFF3F4F6);

  // Funnel steps
  static const funnelStep1 = AppColors.primary;
  static const funnelStep2 = AppColors.primaryLight;
  static const funnelStep3 = AppColors.primaryMuted;

  // Medidas
  static const radius = 12.0;
  static const cardPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
}
