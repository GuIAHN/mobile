import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

/// Pastilla pequeña para mostrar un contador junto a un título de sección
/// (p. ej. "MI GARAGE · 3", "ESPECIALIDADES · 2").
class CountPill extends StatelessWidget {
  final int count;
  final Color? backgroundColor;
  final Color? textColor;

  const CountPill({
    super.key,
    required this.count,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // No escala con el tamaño de texto del sistema: es un badge numérico
    // decorativo (el conteo real ya es legible en el contenido de la
    // sección), así evitamos overflow del encabezado con Dynamic Type.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.primaryMuted,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          '$count',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: textColor ?? AppColors.primary,
          ),
        ),
      ),
    );
  }
}
