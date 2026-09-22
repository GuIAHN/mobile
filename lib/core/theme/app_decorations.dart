import 'package:flutter/material.dart';
import 'app_spacing.dart';

/// Tokens de decoración compartidos: radios y sombras.
///
/// Objetivo: una sola escala de radio y solo tres niveles de sombra en toda
/// la app. No introducir valores nuevos fuera de estos tokens.
abstract class AppDecorations {
  AppDecorations._();

  // ── Radios ────────────────────────────────────────────────────────────
  // Reutiliza AppSpacing.radius* — badges: sm(8), inputs/chips: md(12),
  // TODAS las cards: lg(16), pills: full.
  static const double radiusCard = AppSpacing.radiusLg; // 16
  static const double radiusSheet = 28.0;

  static BorderRadius get card => BorderRadius.circular(radiusCard);
  static BorderRadius get sheet =>
      const BorderRadius.vertical(top: Radius.circular(radiusSheet));

  // ── Sombras ───────────────────────────────────────────────────────────

  /// Cards en reposo (listas, secciones).
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  /// Elementos flotantes: barra de búsqueda, sheets, botones elevados.
  static List<BoxShadow> get raised => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}
