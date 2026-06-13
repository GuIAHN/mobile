import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class SpecialtyItem {
  final IconData icono;
  final String nombre;
  final String descripcion;
  const SpecialtyItem(this.icono, this.nombre, this.descripcion);
}

class WorkshopSpecialtiesStep extends StatelessWidget {
  final Set<int> selectedSpecialties;
  final ValueChanged<int> onSpecialtyToggled;
  final List<SpecialtyItem> specialties;
  final String cardTitle;
  final String cardDescription;

  static const defaultSpecialties = [
    SpecialtyItem(Icons.settings_outlined, 'Mecánica General',
        'Motor, transmisión y mantenimiento preventivo integral.'),
    SpecialtyItem(Icons.format_paint_outlined, 'Latonería y Pintura',
        'Restauración de carrocería y acabados de alta gama.'),
    SpecialtyItem(Icons.album_outlined, 'Frenos',
        'Sistemas ABS, discos, pastillas y seguridad activa.'),
    SpecialtyItem(Icons.swap_vert_outlined, 'Suspensión',
        'Amortiguación, dirección y alineación técnica.'),
    SpecialtyItem(Icons.ac_unit, 'Aire Acondicionado',
        'Carga de gas, compresores y climatización.'),
    SpecialtyItem(Icons.bolt_outlined, 'Electricidad',
        'Diagnóstico electrónico, sensores y cableado.'),
  ];

  const WorkshopSpecialtiesStep({
    super.key,
    required this.selectedSpecialties,
    required this.onSpecialtyToggled,
    this.specialties = defaultSpecialties,
    this.cardTitle = 'Capacidad Técnica',
    this.cardDescription = 'Su selección define el tipo de órdenes de servicio que recibirá en el panel de administración. Asegúrese de contar con las herramientas certificadas para cada especialidad elegida.',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...List.generate(specialties.length, (i) {
          final e = specialties[i];
          final activa = selectedSpecialties.contains(i);
          return GestureDetector(
            onTap: () => onSpecialtyToggled(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: activa ? const Color(0xFFFFF8F4) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: activa ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
                boxShadow: activa
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.10),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: activa
                          ? AppColors.primary.withOpacity(0.10) // naranjaSuave
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      e.icono,
                      size: 22,
                      color: activa ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.nombre,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          e.descripcion,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.check_circle,
                    size: 22,
                    color: activa ? AppColors.primary : AppColors.border,
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        // Card Capacidad Técnica
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cardTitle,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                cardDescription,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
