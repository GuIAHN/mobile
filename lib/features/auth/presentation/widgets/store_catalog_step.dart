import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../catalog/domain/entities/category.dart';
import '../../../catalog/domain/entities/category_node.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import 'store_catalog_helper.dart';

class StoreCatalogStep extends ConsumerStatefulWidget {
  const StoreCatalogStep({
    super.key,
    required this.catalogo,
    required this.onSubcategoryToggled,
  });

  final List<LineaCatalogo> catalogo;
  final void Function(Category category, Category subcategory)
      onSubcategoryToggled;

  @override
  ConsumerState<StoreCatalogStep> createState() => _StoreCatalogStepState();
}

class _StoreCatalogStepState extends ConsumerState<StoreCatalogStep> {
  bool _isSelected(String id) =>
      widget.catalogo.any((line) => line.category.id == id);

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

  Future<void> _openCategory(
    BuildContext context,
    CategoryNode root,
    List<CategoryNode> descendants,
  ) async {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final selectedIds = descendants
        .where((node) => _isSelected(node.id))
        .map((node) => node.id)
        .toSet();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      sheetAnimationStyle: AnimationStyle(
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 280),
        reverseDuration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
      ),
      builder: (_) => _CategoryOptionsSheet(
        root: root,
        options: descendants,
        initiallySelectedIds: selectedIds,
        onToggle: (node) => widget.onSubcategoryToggled(
          Category(id: root.id, name: root.name),
          Category(
            id: node.id,
            name: node.name,
            parentId: node.parentId,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final treeAsync = ref.watch(categoryTreeProvider);

    return treeAsync.when(
      loading: () => const _CatalogState.loading(),
      error: (_, __) => _CatalogState.error(
        onRetry: () => ref.invalidate(categoryTreeProvider),
      ),
      data: (roots) {
        if (roots.isEmpty) return const _CatalogState.empty();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final columns =
                    constraints.maxWidth >= 300 && textScale < 1.6 ? 2 : 1;
                final cards = roots.map((root) {
                  final descendants = _descendants(root);
                  final selectedCount =
                      descendants.where((node) => _isSelected(node.id)).length;
                  return _CategoryCard(
                    key: Key('store-category-${root.id}'),
                    title: root.name,
                    optionCount: descendants.length,
                    selectedCount: selectedCount,
                    onTap: () => _openCategory(context, root, descendants),
                  );
                }).toList();

                if (columns == 1) {
                  return Column(
                    children: [
                      for (var index = 0; index < cards.length; index++) ...[
                        cards[index],
                        if (index < cards.length - 1)
                          const SizedBox(height: 12),
                      ],
                    ],
                  );
                }

                return Column(
                  children: [
                    for (var index = 0; index < cards.length; index += 2) ...[
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: cards[index]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: index + 1 < cards.length
                                  ? cards[index + 1]
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                      if (index + 2 < cards.length) const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    super.key,
    required this.title,
    required this.optionCount,
    required this.selectedCount,
    required this.onTap,
  });

  final String title;
  final int optionCount;
  final int selectedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = selectedCount > 0;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final categoryIcon = _categoryIcon(title);

    return Semantics(
      button: true,
      selected: selected,
      label:
          '$title, ${selected ? '$selectedCount seleccionados' : '$optionCount disponibles'}',
      onTapHint: 'Abrir lista de repuestos',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 126),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryMuted : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
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
                Row(
                  children: [
                    AppLineIcon(
                      categoryIcon,
                      size: AppIconSize.action,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    const Spacer(),
                    AppLineIcon(
                      selected ? AppIcons.success : AppIcons.next,
                      size: AppIconSize.inline,
                      color: selected
                          ? AppColors.successInk
                          : AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    height: 1.18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  selected
                      ? '$selectedCount seleccionados'
                      : '$optionCount disponibles',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryOptionsSheet extends StatefulWidget {
  const _CategoryOptionsSheet({
    required this.root,
    required this.options,
    required this.initiallySelectedIds,
    required this.onToggle,
  });

  final CategoryNode root;
  final List<CategoryNode> options;
  final Set<String> initiallySelectedIds;
  final ValueChanged<CategoryNode> onToggle;

  @override
  State<_CategoryOptionsSheet> createState() => _CategoryOptionsSheetState();
}

class _CategoryOptionsSheetState extends State<_CategoryOptionsSheet> {
  late final Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.of(widget.initiallySelectedIds);
  }

  void _toggle(CategoryNode option) {
    setState(() {
      if (!_selectedIds.remove(option.id)) _selectedIds.add(option.id);
    });
    widget.onToggle(option);
  }

  void _toggleAll() {
    final allSelected = widget.options.isNotEmpty &&
        widget.options.every((option) => _selectedIds.contains(option.id));
    final changedOptions = widget.options
        .where(
          (option) => allSelected
              ? _selectedIds.contains(option.id)
              : !_selectedIds.contains(option.id),
        )
        .toList();

    setState(() {
      if (allSelected) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(widget.options.map((option) => option.id));
      }
    });

    for (final option in changedOptions) {
      widget.onToggle(option);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final usesLargeText = mediaQuery.textScaler.scale(14) >= 21;
    final heightFactor = usesLargeText ? 0.95 : 0.82;
    final allSelected = widget.options.isNotEmpty &&
        widget.options.every((option) => _selectedIds.contains(option.id));

    return Container(
      height: mediaQuery.size.height * heightFactor,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textDisabled,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppLineIcon(
                      _categoryIcon(widget.root.name),
                      size: AppIconSize.leading,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        widget.root.name,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Flex(
                  direction: usesLargeText ? Axis.vertical : Axis.horizontal,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        '${_selectedIds.length} elegidos',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13.5,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (!usesLargeText) const SizedBox(width: 12),
                    TextButton(
                      key: const Key('toggle-all-store-subcategories'),
                      onPressed: widget.options.isEmpty ? null : _toggleAll,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        foregroundColor: AppColors.primary,
                        disabledForegroundColor: AppColors.textDisabled,
                        textStyle: GoogleFonts.hankenGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Text(
                        allSelected ? 'Quitar todas' : 'Seleccionar todas',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.options.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: _CatalogState.noOptions(),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    itemCount: widget.options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final option = widget.options[index];
                      return _SubcategoryRow(
                        key: Key('store-subcategory-${option.id}'),
                        label: option.name,
                        selected: _selectedIds.contains(option.id),
                        onTap: () => _toggle(option),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('close-store-category-sheet'),
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  elevation: 0,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                child: Text(
                  _selectedIds.isEmpty
                      ? 'LISTO'
                      : 'LISTO · ${_selectedIds.length}',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _categoryIcon(String categoryName) {
  final name = categoryName
      .toLowerCase()
      .replaceAll(RegExp('[áàäâ]'), 'a')
      .replaceAll(RegExp('[éèëê]'), 'e')
      .replaceAll(RegExp('[íìïî]'), 'i')
      .replaceAll(RegExp('[óòöô]'), 'o')
      .replaceAll(RegExp('[úùüû]'), 'u')
      .replaceAll('ñ', 'n');

  if (name.contains('clima') || name.contains('aire')) {
    return AppIcons.climate;
  }
  if (name.contains('carroceria') || name.contains('pintura')) {
    return AppIcons.bodywork;
  }
  if (name.contains('caucho') ||
      name.contains('rin') ||
      name.contains('rueda')) {
    return AppIcons.wheels;
  }
  if (name.contains('direccion') || name.contains('suspension')) {
    return AppIcons.suspension;
  }
  if (name.contains('electric') || name.contains('encendido')) {
    return AppIcons.electrical;
  }
  if (name.contains('freno')) return AppIcons.brakes;
  if (name.contains('motor')) return AppIcons.engine;
  if (name.contains('audio') || name.contains('multimedia')) {
    return AppIcons.audio;
  }
  if (name.contains('combustible')) return AppIcons.fuel;
  if (name.contains('iluminacion') || name.contains('luz')) {
    return AppIcons.lighting;
  }
  if (name.contains('transmision')) return AppIcons.transmission;
  return AppIcons.catalog;
}

class _SubcategoryRow extends StatelessWidget {
  const _SubcategoryRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTapHint: selected ? 'Quitar selección' : 'Seleccionar',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryMuted : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 150),
                  child: const AppLineIcon(
                    AppIcons.selected,
                    size: AppIconSize.action,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
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
        icon = AppIcons.catalog,
        onRetry = null;
  const _CatalogState.noOptions()
      : message = 'Esta categoría no tiene repuestos disponibles.',
        icon = AppIcons.catalog,
        onRetry = null;
  const _CatalogState.error({required this.onRetry})
      : message = 'No pudimos cargar las categorías.',
        icon = AppIcons.cloudError;

  final String message;
  final IconData? icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon == null)
                const CircularProgressIndicator(color: AppColors.primary)
              else
                AppLineIcon(
                  icon!,
                  color: AppColors.textSecondary,
                  size: AppIconSize.feature,
                ),
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
                  icon: const AppLineIcon(
                    AppIcons.retry,
                    size: AppIconSize.action,
                  ),
                  label: const Text('REINTENTAR'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
