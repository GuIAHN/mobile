import 'package:flutter/material.dart';

/// Agrupa una sección destacada del Home sin añadir una segunda superficie.
///
/// El contenido hijo conserva sus propios márgenes y cards, evitando el doble
/// fondo alrededor de los carruseles y manteniendo el mismo patrón por rol.
class HomeSectionSurface extends StatelessWidget {
  const HomeSectionSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
        key: const Key('home-section-content'),
        width: double.infinity,
        child: child,
      );
}
