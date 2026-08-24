import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import 'store_catalog_helper.dart';

class StoreSummaryStep extends StatelessWidget {
  final List<LineaCatalogo> catalogo;
  final VoidCallback onConfigurarCatalogo;

  const StoreSummaryStep({
    super.key,
    required this.catalogo,
    required this.onConfigurarCatalogo,
  });

  @override
  Widget build(BuildContext context) {
    final marcasUnicas =
        catalogo.expand((l) => l.brands.map((b) => b.name)).toSet();
    final marcasStr = marcasUnicas.join(', ');
    final configured = catalogo.isNotEmpty &&
        catalogo.first.brands.isNotEmpty &&
        catalogo.first.sparePartsTypes.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: configured ? AppColors.primary : AppColors.border,
              width: configured ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'CONFIGURACIÓN GENERAL',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                configured
                    ? 'Marcas y tipos configurados'
                    : 'Define lo que maneja tu tienda',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Esta selección se aplicará automáticamente a todas las subcategorías elegidas.',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13.5,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const Key('configure-general-store-catalog'),
                onPressed: onConfigurarCatalogo,
                icon: const Icon(Icons.tune_rounded),
                label: Text(configured ? 'EDITAR CONFIGURACIÓN' : 'CONFIGURAR'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...catalogo.map((l) {
          final icon = getCategoryIcon(l.category.name);
          return _CardLinea(
            linea: l,
            icono: icon,
            onTap: onConfigurarCatalogo,
          );
        }),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tu catálogo define tus clientes',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'El sistema mostrará tu tienda a los usuarios que busquen repuestos de las marcas configuradas (${marcasStr.isEmpty ? 'Ninguna marca seleccionada' : marcasStr}). Puedes volver atrás para agregar más marcas o subcategorías.',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13.5,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _CardLinea extends StatelessWidget {
  final LineaCatalogo linea;
  final IconData icono;
  final VoidCallback onTap;

  const _CardLinea({
    required this.linea,
    required this.icono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /* Icono */
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icono,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              /* Detalles */
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      linea.category.name,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Categoría: ${linea.parentCategory.name}',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Usa la configuración general',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textDisabled,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
