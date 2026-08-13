import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Escala tipográfica única de guIAutomotriz.
///
/// Fuente: Hanken Grotesk en todos los tamaños. Estos son los ÚNICOS
/// tamaños de texto permitidos en la app — no crear tamaños ad-hoc inline.
abstract class AppTypography {
  AppTypography._();

  /// 26px w800 — Saludo del header, cifras destacadas.
  static TextStyle get display => GoogleFonts.hankenGrotesk(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.15,
        color: AppColors.textPrimary,
      );

  /// 22px w800 — Título de pantalla, título de paso de wizard.
  static TextStyle get h1 => GoogleFonts.hankenGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        height: 1.2,
        color: AppColors.textPrimary,
      );

  /// 18px w800 — Encabezado de sección.
  static TextStyle get h2 => GoogleFonts.hankenGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        height: 1.2,
        color: AppColors.textPrimary,
      );

  /// 16px w700 — Título de card.
  static TextStyle get title => GoogleFonts.hankenGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.25,
        color: AppColors.textPrimary,
      );

  /// 15px w500 — Texto corrido, valor de input.
  static TextStyle get body => GoogleFonts.hankenGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  /// 13px w500 — Texto secundario, subtítulos.
  static TextStyle get bodySm => GoogleFonts.hankenGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: AppColors.textSecondary,
      );

  /// 13px w700 — Botones y links.
  static TextStyle get label => GoogleFonts.hankenGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: AppColors.textPrimary,
      );

  /// 12px w600 — Metadata: distancia, rating, timestamps, chips.
  static TextStyle get meta => GoogleFonts.hankenGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      );

  /// 12px w700 tracking 1.5 MAYÚSCULAS — Labels de formulario.
  static TextStyle get overline => GoogleFonts.hankenGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: AppColors.textSecondary,
      );
}
