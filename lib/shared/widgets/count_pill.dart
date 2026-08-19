import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

/// Pastilla pequeña para mostrar un contador junto a un título de sección
/// (p. ej. "MI GARAGE · 3", "ESPECIALIDADES · 2"). Usa el tono celeste
/// reservado para contadores/metadata en el sistema de diseño.
class CountPill extends StatelessWidget {
  final int count;

  const CountPill({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    // No escala con el tamaño de texto del sistema: es un badge numérico
    // decorativo (el conteo real ya es legible en el contenido de la
    // sección), así evitamos overflow del encabezado con Dynamic Type.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.celesteMuted,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          '$count',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.celesteInk,
          ),
        ),
      ),
    );
  }
}
