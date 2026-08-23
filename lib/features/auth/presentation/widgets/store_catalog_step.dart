import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/catalog_summary_card.dart';
import '../../../catalog/domain/entities/category.dart';
import 'store_catalog_helper.dart';

class StoreCatalogStep extends StatelessWidget {
  final List<LineaCatalogo> catalogo;
  final ValueChanged<LineaCatalogo> onAbrirSheetMarcas;
  final VoidCallback onAgregarSubcategoria;

  const StoreCatalogStep({
    super.key,
    required this.catalogo,
    required this.onAbrirSheetMarcas,
    required this.onAgregarSubcategoria,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16, top: 4),
          child: Text(
            'SUBCATEGORÍAS QUE MANEJA TU TIENDA',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        if (catalogo.isEmpty) const _EmptyCatalogState(),
        ...catalogo.map((linea) {
          final cat = linea.category;
          return _CardCategoria(
            category: cat,
            linea: linea,
            onTap: () => onAbrirSheetMarcas(linea),
          );
        }),
        const SizedBox(height: 4),
        Semantics(
          button: true,
          label: 'Agregar una subcategoría al catálogo de la tienda',
          child: OutlinedButton.icon(
            key: const Key('add-store-subcategory'),
            onPressed: onAgregarSubcategoria,
            icon: const Icon(Icons.add_rounded, size: 22),
            label: Text(
              catalogo.isEmpty
                  ? 'SELECCIONAR SUBCATEGORÍA'
                  : 'AGREGAR OTRA SUBCATEGORÍA',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              textStyle: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
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
    final sparePartTypes = linea?.sparePartsTypes ?? {};
    final configured = marcas.isNotEmpty && sparePartTypes.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CatalogSummaryCard(
        key: ValueKey('store-catalog-category-${category.id}'),
        title: category.name,
        icon: getCategoryIcon(category.name),
        brandSummary: marcas.isEmpty
            ? 'Sin marcas seleccionadas'
            : '${marcas.length} ${marcas.length == 1 ? 'marca' : 'marcas'}',
        sparePartTypes: sparePartTypes,
        configured: configured,
        actionLabel: configured ? 'Editar' : 'Configurar',
        onTap: onTap,
      ),
    );
  }
}

class _EmptyCatalogState extends StatelessWidget {
  const _EmptyCatalogState();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Todavía no has seleccionado subcategorías',
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.account_tree_outlined,
              color: AppColors.primary,
              size: 36,
            ),
            const SizedBox(height: 16),
            Text(
              'Selecciona lo que vendes',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Explora las categorías y elige una subcategoría para configurar sus marcas y tipos de repuesto.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
