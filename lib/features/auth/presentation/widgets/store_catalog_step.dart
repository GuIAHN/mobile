import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../catalog/domain/entities/category.dart';
import 'store_catalog_helper.dart';

class StoreCatalogStep extends StatelessWidget {
  final List<LineaCatalogo> catalogo;
  final List<Category> categories;
  final ValueChanged<Category> onAbrirSheetMarcas;

  const StoreCatalogStep({
    super.key,
    required this.catalogo,
    required this.categories,
    required this.onAbrirSheetMarcas,
  });

  LineaCatalogo? _buscarLinea(String categoryId) {
    for (final l in catalogo) {
      if (l.category.id == categoryId) return l;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48),
        alignment: Alignment.center,
        child: Column(
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Cargando categorías de la API...',
              style: GoogleFonts.hankenGrotesk(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16, top: 4),
          child: Text(
            'SELECCIONA LAS MARCAS QUE MANEJAS EN CADA CATEGORÍA',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ...categories.map((cat) {
          final linea = _buscarLinea(cat.id);
          return _CardCategoria(
            category: cat,
            linea: linea,
            onTap: () => onAbrirSheetMarcas(cat),
          );
        }),
      ],
    );
  }
}

/* ───────────────── Widgets de Soporte Local ───────────────── */

class _CardCategoria extends StatelessWidget {
  final Category category;
  final LineaCatalogo? linea;
  final VoidCallback onTap;

  const _CardCategoria({
    required this.category,
    required this.linea,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final marcas = linea?.brands ?? {};
    final activa = marcas.isNotEmpty;

    final icon = getCategoryIcon(category.name);
    final desc = getCategoryDescription(category.name);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: activa ? AppColors.primaryMuted : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: activa ? AppColors.primary : AppColors.border,
            width: activa ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(activa ? 0.05 : 0.03),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                /* Icono de Categoría */
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: activa
                        ? AppColors.primary.withOpacity(0.12)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: activa ? AppColors.primary : AppColors.textSecondary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                /* Nombre y Descripción */
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
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
                /* Badge de conteo o Chevron */
                activa
                    ? _BadgeCount(marcas.length)
                    : const Icon(
                        Icons.add_circle_outline,
                        color: AppColors.textDisabled,
                        size: 24,
                      ),
              ],
            ),
            /* Marcas y tipos seleccionados */
            if (activa) ...[
              const SizedBox(height: 14),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 12),
              Text(
                'MARCAS:',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDisabled,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: marcas.map((m) => _ChipMarca(m.name)).toList(),
              ),
              const SizedBox(height: 12),
              Text(
                'TIPOS DE REPUESTO:',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDisabled,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: linea!.sparePartsTypes.map((t) {
                  switch (t) {
                    case 'ORIGINAL':
                      return const _ChipTipo('Original');
                    case 'GENERIC':
                      return const _ChipTipo('Genérico');
                    case 'PERFORMANCE':
                      return const _ChipTipo('Performance');
                    default:
                      return _ChipTipo(t);
                  }
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChipMarca extends StatelessWidget {
  final String marca;
  const _ChipMarca(this.marca);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1.2,
        ),
      ),
      child: Text(
        marca,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _ChipTipo extends StatelessWidget {
  final String tipo;
  const _ChipTipo(this.tipo);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1.2,
        ),
      ),
      child: Text(
        tipo,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _BadgeCount extends StatelessWidget {
  final int count;
  const _BadgeCount(this.count);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '$count ${count == 1 ? 'marca' : 'marcas'}',
        style: GoogleFonts.hankenGrotesk(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
