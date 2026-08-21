import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../catalog/domain/entities/specialty.dart';

/// Funciones auxiliares para mapear especialidades dinámicas del backend a iconos e información estética.
IconData getSpecialtyIcon(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('aire') || lower.contains('climatización')) {
    return Icons.ac_unit_outlined;
  }
  if (lower.contains('tuning') ||
      lower.contains('reprogramación') ||
      lower.contains('computadoras')) {
    return Icons.computer_outlined;
  }
  if (lower.contains('escaneo') || lower.contains('diagnóstico')) {
    return Icons.troubleshoot_outlined;
  }
  if (lower.contains('detallado') ||
      lower.contains('detailing') ||
      lower.contains('estética')) {
    return Icons.auto_awesome_outlined;
  }
  if (lower.contains('electricidad') || lower.contains('electrónica')) {
    return Icons.bolt_outlined;
  }
  if (lower.contains('latonería') ||
      lower.contains('pintura') ||
      lower.contains('restauración')) {
    return Icons.format_paint_outlined;
  }
  if (lower.contains('frenos') || lower.contains('abs')) {
    return Icons.album_outlined;
  }
  if (lower.contains('suspensión') ||
      lower.contains('dirección') ||
      lower.contains('alineación')) {
    return Icons.swap_vert_outlined;
  }
  if (lower.contains('transmisiones automáticas') || lower.contains('cvt')) {
    return Icons.swap_horizontal_circle_outlined;
  }
  if (lower.contains('transmisiones manuales') || lower.contains('embragues')) {
    return Icons.account_tree_outlined;
  }
  if (lower.contains('turbo') || lower.contains('inducción')) {
    return Icons.speed_outlined;
  }
  return Icons.settings_outlined; // Mecánica General / Default
}

String getSpecialtyDescription(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('aire') || lower.contains('climatización')) {
    return 'Carga de gas refrigerante, compresores y sistemas de climatización.';
  }
  if (lower.contains('tuning') || lower.contains('reprogramación')) {
    return 'Programación de ECU, mapeos de motor e incrementos de potencia seguros.';
  }
  if (lower.contains('escaneo') || lower.contains('diagnóstico')) {
    return 'Diagnóstico computarizado por OBDII, lectura de sensores en tiempo real.';
  }
  if (lower.contains('detallado') || lower.contains('detailing')) {
    return 'Corrección de barniz, recubrimientos cerámicos e higienización de habitáculo.';
  }
  if (lower.contains('electricidad') || lower.contains('electrónica')) {
    return 'Alternadores, encendido, cableados complejos, sensores y módulos electrónicos.';
  }
  if (lower.contains('latonería') || lower.contains('pintura')) {
    return 'Desabolladura técnica, restauración de carrocería y acabados premium.';
  }
  if (lower.contains('frenos') || lower.contains('abs')) {
    return 'Pastillas, discos, purga hidráulica, cilindros maestros y sistemas ABS.';
  }
  if (lower.contains('suspensión') || lower.contains('alineación')) {
    return 'Amortiguadores, terminales de dirección, alineación 3D y balanceo.';
  }
  if (lower.contains('transmisión') ||
      lower.contains('cvt') ||
      lower.contains('embrague')) {
    return 'Diagnóstico, reconstrucción de cajas de cambios y kits de embrague.';
  }
  if (lower.contains('turbo')) {
    return 'Mantenimiento de turbocargadores, actuadores de vacío y sistemas de inducción.';
  }
  return 'Mantenimiento preventivo, afinación de motor y servicios generales.';
}

class WorkshopSpecialtiesStep extends StatelessWidget {
  final Set<String> selectedSpecialtyIds;
  final ValueChanged<String> onSpecialtyToggled;
  final List<Specialty> specialties;
  final String cardTitle;
  final String cardDescription;
  final bool isLoading;
  final Object? loadError;
  final VoidCallback? onRetry;

  const WorkshopSpecialtiesStep({
    super.key,
    required this.selectedSpecialtyIds,
    required this.onSpecialtyToggled,
    required this.specialties,
    this.cardTitle = 'Capacidad Técnica',
    this.cardDescription =
        'Su selección define el tipo de órdenes de servicio que recibirá en el panel de administración. Asegúrese de contar con las herramientas certificadas para cada especialidad elegida.',
    this.isLoading = false,
    this.loadError,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (specialties.isEmpty) {
      return _SpecialtiesState(
        isLoading: isLoading,
        hasError: loadError != null,
        onRetry: onRetry,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...specialties.map((specialty) {
          final active = selectedSpecialtyIds.contains(specialty.id);
          final icon = getSpecialtyIcon(specialty.name);
          final desc = getSpecialtyDescription(specialty.name);

          return GestureDetector(
            onTap: () => onSpecialtyToggled(specialty.id),
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: active ? const Color(0xFFFFF8F4) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.10),
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
                      color: active
                          ? AppColors.primary.withValues(alpha: 0.10)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color:
                          active ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          specialty.name,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          desc,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 12.5,
                            height: 1.4,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check_circle,
                    size: 22,
                    color: active ? AppColors.primary : AppColors.border,
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
                color: Colors.black.withValues(alpha: 0.04),
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

class _SpecialtiesState extends StatelessWidget {
  const _SpecialtiesState({
    required this.isLoading,
    required this.hasError,
    this.onRetry,
  });

  final bool isLoading;
  final bool hasError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            if (isLoading)
              const CircularProgressIndicator(color: AppColors.primary)
            else
              Icon(
                hasError ? Icons.cloud_off_outlined : Icons.build_outlined,
                color: hasError ? AppColors.error : AppColors.textSecondary,
                size: 36,
              ),
            const SizedBox(height: 16),
            Text(
              hasError
                  ? 'No pudimos cargar las especialidades'
                  : isLoading
                      ? 'Cargando especialidades…'
                      : 'No hay especialidades disponibles',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasError
                  ? 'Revisa tu conexión e inténtalo nuevamente.'
                  : isLoading
                      ? 'Esto puede tomar unos segundos.'
                      : 'Inténtalo más tarde o comunícate con soporte.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (hasError && onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('REINTENTAR'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(160, 48),
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
