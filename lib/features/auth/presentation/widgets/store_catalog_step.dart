import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../catalog/domain/entities/category.dart';
import '../../../catalog/domain/entities/category_node.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import 'store_catalog_helper.dart';

class StoreCatalogStep extends ConsumerWidget {
  const StoreCatalogStep({
    super.key,
    required this.catalogo,
    required this.onSubcategoryToggled,
  });

  final List<LineaCatalogo> catalogo;
  final void Function(Category category, Category subcategory)
      onSubcategoryToggled;

  bool _isSelected(String id) => catalogo.any((line) => line.category.id == id);

  List<CategoryNode> _descendants(CategoryNode root) {
    final result = <CategoryNode>[];
    void collect(CategoryNode node) {
      for (final child in node.children) {
        result.add(child);
        collect(child);
      }
    }

    collect(root);
    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeAsync = ref.watch(categoryTreeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'CATEGORÍAS Y SUBCATEGORÍAS',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Abre una categoría y selecciona todas las subcategorías que maneja tu tienda.',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 13.5,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        treeAsync.when(
          loading: () => const _CatalogState.loading(),
          error: (_, __) => _CatalogState.error(
            onRetry: () => ref.invalidate(categoryTreeProvider),
          ),
          data: (roots) => roots.isEmpty
              ? const _CatalogState.empty()
              : Column(
                  children: roots.map((root) {
                    final descendants = _descendants(root);
                    final selectedCount = descendants
                        .where((node) => _isSelected(node.id))
                        .length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CategoryAccordion(
                        root: root,
                        descendants: descendants,
                        selectedCount: selectedCount,
                        isSelected: _isSelected,
                        onToggle: (node) => onSubcategoryToggled(
                          Category(id: root.id, name: root.name),
                          Category(
                            id: node.id,
                            name: node.name,
                            parentId: node.parentId,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _CategoryAccordion extends StatelessWidget {
  const _CategoryAccordion({
    required this.root,
    required this.descendants,
    required this.selectedCount,
    required this.isSelected,
    required this.onToggle,
  });

  final CategoryNode root;
  final List<CategoryNode> descendants;
  final int selectedCount;
  final bool Function(String id) isSelected;
  final ValueChanged<CategoryNode> onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selectedCount > 0 ? AppColors.primary : AppColors.border,
          width: selectedCount > 0 ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey('store-category-${root.id}'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textSecondary,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryMuted,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            getCategoryIcon(root.name),
            color: AppColors.primary,
            size: 24,
          ),
        ),
        title: Text(
          root.name,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          selectedCount == 0
              ? '${descendants.length} disponibles'
              : '$selectedCount seleccionadas',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color:
                selectedCount > 0 ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        children: descendants.map((node) {
          final selected = isSelected(node.id);
          return CheckboxListTile(
            key: Key('store-subcategory-${node.id}'),
            value: selected,
            onChanged: (_) => onToggle(node),
            controlAffinity: ListTileControlAffinity.trailing,
            activeColor: AppColors.primary,
            checkboxShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            title: Text(
              node.name,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CatalogState extends StatelessWidget {
  const _CatalogState.loading()
      : message = 'Cargando categorías…',
        icon = null,
        onRetry = null;
  const _CatalogState.empty()
      : message = 'No hay categorías disponibles.',
        icon = Icons.inventory_2_outlined,
        onRetry = null;
  const _CatalogState.error({required this.onRetry})
      : message = 'No pudimos cargar las categorías.',
        icon = Icons.cloud_off_outlined;

  final String message;
  final IconData? icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            if (icon == null)
              const CircularProgressIndicator(color: AppColors.primary)
            else
              Icon(icon, color: AppColors.textSecondary, size: 36),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('REINTENTAR'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
