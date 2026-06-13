/// Sistema de espaciado de guIAutomotriz.
/// Basado en una grilla de 4 px para coherencia visual.
abstract class AppSpacing {
  AppSpacing._();

  // ── Base grid: 4 px ──────────────────────────────────────────────────────
  static const double xs2 = 2.0;   // 2 px
  static const double xs = 4.0;    // 4 px
  static const double sm = 8.0;    // 8 px
  static const double md = 12.0;   // 12 px
  static const double lg = 16.0;   // 16 px
  static const double xl = 20.0;   // 20 px
  static const double xl2 = 24.0;  // 24 px
  static const double xl3 = 32.0;  // 32 px
  static const double xl4 = 40.0;  // 40 px
  static const double xl5 = 48.0;  // 48 px
  static const double xl6 = 64.0;  // 64 px
  static const double xl7 = 80.0;  // 80 px
  static const double xl8 = 96.0;  // 96 px

  // ── Radios de borde ──────────────────────────────────────────────────────
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  // ── Padding de pantalla ─────────────────────────────────────────────────
  static const double screenHorizontal = lg;   // 16 px en lados
  static const double screenVertical = xl2;    // 24 px arriba/abajo

  // ── Íconos ──────────────────────────────────────────────────────────────
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // ── Altura de botones ────────────────────────────────────────────────────
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 48.0;
  static const double buttonHeightLg = 56.0;
}
