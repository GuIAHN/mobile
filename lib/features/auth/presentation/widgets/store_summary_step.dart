import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import 'store_catalog_helper.dart';

class StoreSummaryStep extends StatelessWidget {
  final List<LineaCatalogo> catalogo;
  final ValueChanged<LineaCatalogo> onAbrirSheetMarcas;

  const StoreSummaryStep({
    super.key,
    required this.catalogo,
    required this.onAbrirSheetMarcas,
  });

  @override
  Widget build(BuildContext context) {
    final marcasUnicas =
        catalogo.expand((l) => l.brands.map((b) => b.name)).toSet();
    final marcasStr = marcasUnicas.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...catalogo.map((l) {
          final icon = getCategoryIcon(l.category.name);
          return _CardLinea(
            linea: l,
            icono: icon,
            onTap: () => onAbrirSheetMarcas(l),
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
    final brandNames = linea.brands.map((b) => b.name).join(', ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
                    'Marcas: $brandNames',
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
                    'Calidad: ${linea.sparePartsTypes.map((t) {
                      switch (t) {
                        case 'ORIGINAL':
                          return 'Original';
                        case 'GENERIC':
                          return 'Genérico';
                        case 'PERFORMANCE':
                          return 'Performance';
                        default:
                          return t;
                      }
                    }).join(", ")}',
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
            /* Badge de conteo */
            _Badge(
              '${linea.brands.length} ${linea.brands.length == 1 ? 'marca' : 'marcas'}',
              suave: true,
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textDisabled,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String texto;
  final bool suave;

  const _Badge(this.texto, {this.suave = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: suave ? AppColors.primaryMuted : AppColors.primary,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        texto,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: suave ? AppColors.primary : Colors.white,
        ),
      ),
    );
  }
}
