import 'package:flutter/material.dart';

/// Paleta de colores de la aplicación guIAutomotriz.
/// Basada en el sistema de diseño Veloce Automotive System.
abstract class AppColors {
  // ── Primario — Naranja Automotriz ────────────────────────────────────────
  static const Color primary       = Color(0xFFF25C05); // #F25C05 — Naranja principal
  static const Color primaryLight  = Color(0xFFF5813A); // naranja claro
  static const Color primaryDark   = Color(0xFFBF4704); // naranja oscuro
  static const Color primaryMuted  = Color(0xFFFDE8DA); // naranja muy suave (fondo)

  // ── Secundario — Carbón / Near-black ─────────────────────────────────────
  static const Color secondary      = Color(0xFF1A1C1E); // #1A1C1E — Casi negro
  static const Color secondaryLight = Color(0xFF2E3135); // carbón claro
  static const Color secondaryMuted = Color(0xFF6B7280); // gris medio

  // ── Terciario — Azul Tecnológico ─────────────────────────────────────────
  static const Color tertiary      = Color(0xFF3A86FF); // #3A86FF — Azul tecnológico
  static const Color tertiaryLight = Color(0xFF6FA8FF); // azul claro
  static const Color tertiaryMuted = Color(0xFFDBEAFE); // azul muy suave (fondo)

  // ── Celeste — Señales de confianza y metadata ────────────────────────────
  // Rol semántico: verificado, envío, distancia, rating, contadores y el
  // estado "cotizada/en progreso". El naranja queda reservado para
  // precio + acción, así ambos dejan de competir por atención en las cards.
  static const Color celeste       = Color(0xFF0891B2); // iconos ≥24px, bordes, indicadores (3.68:1 sobre blanco)
  static const Color celesteInk    = Color(0xFF0E7490); // texto e iconos <24px (5.36:1 sobre blanco)
  static const Color celesteMuted  = Color(0xFFE0F7FC); // fondo de chips y badges
  static const Color celesteBorder = Color(0xFFA9E3F0); // bordes 1px decorativos

  // ── Neutral — Grises ─────────────────────────────────────────────────────
  static const Color neutral    = Color(0xFFF8F9FA); // #F8F9FA — Fondo neutro
  static const Color grey50     = Color(0xFFF8F9FA);
  static const Color grey100    = Color(0xFFF1F3F5);
  static const Color grey200    = Color(0xFFE9ECEF);
  static const Color grey300    = Color(0xFFDEE2E6);
  static const Color grey400    = Color(0xFFCED4DA);
  static const Color grey500    = Color(0xFFADB5BD);
  static const Color grey600    = Color(0xFF6C757D);
  static const Color grey700    = Color(0xFF495057);
  static const Color grey800    = Color(0xFF343A40);
  static const Color grey900    = Color(0xFF212529);

  // ── Semánticos ──────────────────────────────────────────────────────────
  static const Color success      = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning      = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error        = Color(0xFFEF4444);
  static const Color errorLight   = Color(0xFFFEE2E2);
  static const Color info         = Color(0xFF3A86FF); // mismo que tertiary
  static const Color infoLight    = Color(0xFFDBEAFE);

  // ── Superficie ──────────────────────────────────────────────────────────
  static const Color surface    = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F6FA); // neutral del branding

  // ── Texto ───────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1A1C1E); // secondary del branding
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textDisabled  = Color(0xFFADB5BD);
  static const Color textPlaceholder = Color(0xFFADB5BD);
  static const Color disabledText    = Color(0xFFADB5BD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark    = Color(0xFFFFFFFF);

  // ── Estados Deshabilitados ──────────────────────────────────────────────
  static const Color disabledBackground = Color(0xFFE9ECEF);

  // ── Bordes ──────────────────────────────────────────────────────────────
  static const Color border        = Color(0xFFE9ECEF);
  static const Color borderFocus   = Color(0xFFF25C05); // primary al enfocar

  // ── Tonos "ink" — texto/ícono accesible sobre fondos *Light/*Muted ──────
  // Los pares primary/primaryMuted, success/successLight, etc. no llegan a
  // 4.5:1 (WCAG AA) para texto. Estos tonos sí, sin tocar los tokens base
  // (que se siguen usando para fondos, iconos grandes y acentos).
  static const Color primaryInk = Color(0xFFA83E05); // 5.28:1 sobre primaryMuted
  static const Color successInk = Color(0xFF15803D); // 4.57:1 sobre successLight
  static const Color warningInk = Color(0xFF92400E); // 6.37:1 sobre warningLight
  static const Color errorInk   = Color(0xFFB91C1C); // 5.30:1 sobre errorLight
  static const Color textMeta   = Color(0xFF6C757D); // 4.69:1 sobre blanco — timestamps/metadata (reemplaza textDisabled, que da 2.07:1)

  // ── Login / Auth — Paleta de marca (light) ─────────────────────────────
  // Reemplaza el antiguo tema oscuro; ahora usa el fondo neutro del branding.
  static const Color loginBg             = Color(0xFFF8F9FA); // neutral
  static const Color loginSurface        = Color(0xFFFFFFFF); // blanco puro
  static const Color loginSurfaceHigh    = Color(0xFFF1F3F5); // grey100
  static const Color loginSurfaceHighest = Color(0xFFE9ECEF); // grey200
  static const Color loginPrimary        = Color(0xFFF25C05); // primary
  static const Color loginOnSurface      = Color(0xFF1A1C1E); // secondary (texto oscuro)
  static const Color loginOnSurfaceVar   = Color(0xFF6C757D); // gris medio
  static const Color loginOutlineVar     = Color(0xFFE9ECEF); // grey200
  static const Color loginError          = Color(0xFFEF4444);
  static const Color loginErrorText      = Color(0xFFB91C1C);
}
