import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme/app_colors.dart';

/// Escala tipográfica y de espaciado para las cards del feature chat.
///
/// El problema visual que resuelve: antes cada card definía sus propios
/// tamaños (9, 10, 10.5, 11, 11.5, 12, 12.5, 13, 13.5, 14, 15, 16, 22) y
/// espaciados (4, 6, 8, 10, 12, 14, 16), con pesos casi idénticos entre
/// título, chips y badges. Sin contraste de tamaño/peso nada dominaba y
/// todo competía, así que la jerarquía se intentaba forzar con rellenos de
/// color — de ahí la "sopa de cajas".
///
/// Regla de diseño: la jerarquía se construye con **tamaño, peso y espacio
/// en blanco**, no con fondos. Como máximo un relleno de énfasis por card.
abstract class CardTokens {
  CardTokens._();

  // ── Ritmo vertical (múltiplos de 4) ──────────────────────────────────────
  /// Padding interno de la card.
  static const double pad = 16;

  /// Separación entre bloques (header / cuerpo / footer).
  static const double blockGap = 14;

  /// Separación entre elementos relacionados dentro de un bloque.
  static const double gap = 8;

  /// Separación mínima (título ↔ subtítulo).
  static const double tight = 4;

  /// Separación alrededor del divisor de footer.
  static const double dividerGap = 12;

  // ── Geometría ────────────────────────────────────────────────────────────
  static const double radius = 20;
  static const double thumbRadius = 14;
  static const double thumbSize = 64;
  static const double thumbSizeLarge = 88;

  /// Elevación única y suave. Antes había 4 sombras distintas entre cards.
  static List<BoxShadow> get shadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  // ── Tipografía ───────────────────────────────────────────────────────────

  /// Título de la card (vehículo, tienda, cliente). El elemento dominante.
  static TextStyle get title => GoogleFonts.hankenGrotesk(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        height: 1.2,
        color: AppColors.textPrimary,
      );

  /// Precio protagonista (card de oferta) — el dato que se compara.
  static TextStyle get priceHero => GoogleFonts.hankenGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.6,
        height: 1.1,
        color: AppColors.primary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Precio en línea (footer de solicitud, fila compacta).
  static TextStyle get price => GoogleFonts.hankenGrotesk(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Metadata secundaria: categoría, distancia, contadores, timestamps.
  static TextStyle get meta => GoogleFonts.hankenGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: AppColors.textMeta,
      );

  /// Metadata con énfasis (nombre de tienda en el footer, rating).
  static TextStyle get metaStrong => GoogleFonts.hankenGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.textSecondary,
      );

  /// Etiqueta superior en mayúsculas ("MEJOR OFERTA").
  static TextStyle get overline => GoogleFonts.hankenGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.textMeta,
      );

  /// Texto del badge de estado.
  static TextStyle get status => GoogleFonts.hankenGrotesk(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      );

  /// Cuerpo: nota del cliente, último mensaje.
  static TextStyle get body => GoogleFonts.hankenGrotesk(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.textSecondary,
      );

  /// Último mensaje sin leer — mismo tamaño, más peso y contraste.
  static TextStyle get bodyUnread => GoogleFonts.hankenGrotesk(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  /// Texto de botón.
  static TextStyle get button => GoogleFonts.hankenGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      );
}
