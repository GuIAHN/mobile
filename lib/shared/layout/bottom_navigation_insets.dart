import 'package:flutter/widgets.dart';

const double bottomNavigationBarHeight = 72;
const double bottomNavigationBottomMargin = 8;
const double bottomNavigationLabelFontSize = 12;

/// Espacio inferior que debe reservar el contenido detrás de la navegación.
///
/// Vive en `shared` porque lo consumen varias features; el widget visual de
/// navegación sigue perteneciendo al shell de inicio.
double bottomNavigationContentInset(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final scaledLabelHeight =
      mediaQuery.textScaler.scale(bottomNavigationLabelFontSize);
  final labelGrowth = (scaledLabelHeight - bottomNavigationLabelFontSize).clamp(
    0.0,
    double.infinity,
  );

  return bottomNavigationBarHeight +
      labelGrowth +
      mediaQuery.padding.bottom +
      bottomNavigationBottomMargin;
}
