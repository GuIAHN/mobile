import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../catalog/domain/entities/category.dart';
import '../../../../catalog/domain/entities/category_node.dart';
import '../../../../catalog/presentation/providers/catalog_providers.dart';

/// ID de la subcategoría "Otro" devuelta por [CategorySubcategorySelectorSheet].
///
/// Público a propósito: el paso 3 del wizard necesita comparar contra este
/// valor real (antes comparaba contra el literal 'other_subcategory_id',
/// que nunca coincidía con el UUID real y dejaba la validación de "Otro"
/// muerta).
const kOtherSubcategoryId = '4340eca0-6410-414c-9655-e91711666860';
const kOtherCategoryId = 'f4ff2288-c7bc-4c42-b0ee-0e66a46e0395';

class CategorySubcategoryResult {
  final Category category;
  final Category subcategory;

  const CategorySubcategoryResult({
    required this.category,
    required this.subcategory,
  });
}

class _CategorySearchResult {
  final CategoryNode node;
  final List<String> path;

  const _CategorySearchResult({
    required this.node,
    required this.path,
  });

  String get breadcrumb => path.join(' › ');
}

class CategorySubcategorySelectorSheet extends ConsumerStatefulWidget {
  static Future<CategorySubcategoryResult?> show(
    BuildContext context, {
    Category? initialCategory,
    Category? initialSubcategory,
  }) {
    return showModalBottomSheet<CategorySubcategoryResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      builder: (_) => CategorySubcategorySelectorSheet(
        initialCategory: initialCategory,
        initialSubcategory: initialSubcategory,
      ),
    );
  }

  final Category? initialCategory;
  final Category? initialSubcategory;

  const CategorySubcategorySelectorSheet({
    super.key,
    this.initialCategory,
    this.initialSubcategory,
  });

  @override
  ConsumerState<CategorySubcategorySelectorSheet> createState() =>
      _CategorySubcategorySelectorSheetState();
}

class _CategorySubcategorySelectorSheetState
    extends ConsumerState<CategorySubcategorySelectorSheet> {
  static const _otherCategoryId = kOtherCategoryId;
  static const _otherSubcategoryId = kOtherSubcategoryId;

  List<String> _expandedPath = const [];
  bool _didInitializeExpansion = false;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Duration get _expansionDuration => MediaQuery.of(context).disableAnimations
      ? Duration.zero
      : const Duration(milliseconds: 180);

  void _initializeExpansion(List<CategoryNode> roots) {
    if (_didInitializeExpansion) return;
    _didInitializeExpansion = true;

    final initialId = widget.initialCategory?.id;
    CategoryNode? initialRoot;
    if (initialId != null) {
      for (final root in roots) {
        if (root.id == initialId) {
          initialRoot = root;
          break;
        }
      }
    }
    initialRoot ??= roots.cast<CategoryNode?>().firstWhere(
          (root) => root?.children.isNotEmpty ?? false,
          orElse: () => null,
        );

    if (initialRoot != null && initialRoot.children.isNotEmpty) {
      _expandedPath = <String>[initialRoot.id];
    }
  }

  void _toggleNode(
    CategoryNode node,
    List<CategoryNode> tree,
    List<String> ancestors,
  ) {
    if (node.children.isEmpty) {
      _selectLeaf(node, tree);
      return;
    }

    final depth = ancestors.length;
    final isExpanded =
        _expandedPath.length > depth && _expandedPath[depth] == node.id;
    setState(() {
      _expandedPath = isExpanded
          ? List<String>.of(ancestors)
          : <String>[...ancestors, node.id];
    });
  }

  void _selectLeaf(CategoryNode node, List<CategoryNode> tree) {
    final Category category;
    final Category subcategory;

    if (node.parentId == null) {
      category = Category(id: node.id, name: node.name);
      subcategory = Category(id: node.id, name: node.name);
    } else {
      final root = _findRoot(tree, node);
      category = Category(id: root.id, name: root.name);
      subcategory = Category(
        id: node.id,
        name: node.name,
        parentId: node.parentId,
      );
    }

    Navigator.pop(
      context,
      CategorySubcategoryResult(
        category: category,
        subcategory: subcategory,
      ),
    );
  }

  CategoryNode _findRoot(List<CategoryNode> tree, CategoryNode target) {
    for (final root in tree) {
      if (root.id == target.id || _containsNode(root, target.id)) {
        return root;
      }
    }
    return target;
  }

  bool _containsNode(CategoryNode current, String targetId) {
    for (final child in current.children) {
      if (child.id == targetId || _containsNode(child, targetId)) {
        return true;
      }
    }
    return false;
  }

  void _selectOther() {
    Navigator.pop(
      context,
      const CategorySubcategoryResult(
        category: Category(id: _otherCategoryId, name: 'Otro'),
        subcategory: Category(
          id: _otherSubcategoryId,
          name: 'Otro',
          parentId: _otherCategoryId,
        ),
      ),
    );
  }

  void _handleBack() {
    if (_expandedPath.length > 1) {
      setState(() {
        _expandedPath = _expandedPath.sublist(0, _expandedPath.length - 1);
      });
      return;
    }
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final treeAsync = ref.watch(categoryTreeProvider);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        mediaQuery.padding.bottom + 12,
      ),
      child: Column(
        children: [
          const _SheetHandle(),
          const SizedBox(height: 14),
          _buildHeader(),
          const SizedBox(height: 16),
          _buildSearchField(),
          const SizedBox(height: 16),
          Expanded(
            child: treeAsync.when(
              loading: _buildLoading,
              error: (_, __) => _buildError(),
              data: (tree) => _query.trim().length < 2
                  ? _buildAccordion(tree)
                  : _buildSearchResults(tree),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _selectOther,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryInk,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Otro / no encuentro mi categoría'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _query = value),
      textInputAction: TextInputAction.search,
      style: AppTypography.body,
      decoration: InputDecoration(
        hintText: 'Buscar pieza o categoría',
        hintStyle: AppTypography.body.copyWith(
          color: AppColors.textPlaceholder,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textSecondary,
        ),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpiar búsqueda',
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: AppColors.grey50,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<CategoryNode> tree) {
    final normalized = _query.trim().toLowerCase();
    final results = <_CategorySearchResult>[];
    for (final root in tree.where((node) => !_isOther(node.name))) {
      _collectSearchResults(
        root,
        <String>[root.name],
        normalized,
        results,
      );
    }

    if (results.isEmpty) {
      return _SelectorState(
        icon: Icons.search_off_rounded,
        message: 'No encontramos esa pieza.',
        actionLabel: 'Elegir Otro',
        onAction: _selectOther,
      );
    }

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: results.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, index) {
        final result = results[index];
        return ListTile(
          minTileHeight: 64,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          title: Text(result.node.name, style: AppTypography.title),
          subtitle: Text(
            result.breadcrumb,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySm,
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _selectLeaf(result.node, tree),
        );
      },
    );
  }

  void _collectSearchResults(
    CategoryNode node,
    List<String> path,
    String query,
    List<_CategorySearchResult> results,
  ) {
    if (node.children.isEmpty &&
        (node.name.toLowerCase().contains(query) ||
            path.join(' ').toLowerCase().contains(query))) {
      results.add(_CategorySearchResult(node: node, path: path));
    }
    for (final child in node.children.where((item) => !_isOther(item.name))) {
      _collectSearchResults(
        child,
        <String>[...path, child.name],
        query,
        results,
      );
    }
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _handleBack,
          tooltip: 'Volver',
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PASO 2 DE 3',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textMeta,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                // No "Tipo de repuesto": ese nombre ya lo usa el selector
                // Nuevo/Usado/Reacondicionado del paso 2, y esta hoja elige
                // la categoría del repuesto, un campo distinto.
                'Categoría del repuesto',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.12,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () => Navigator.maybePop(context),
          tooltip: 'Cerrar selector',
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          icon: const Icon(
            Icons.close_rounded,
            size: 26,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildAccordion(List<CategoryNode> tree) {
    final roots = tree.where((node) => !_isOther(node.name)).toList();
    if (roots.isEmpty) {
      return _buildEmpty();
    }

    _initializeExpansion(roots);

    return ListView.separated(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      itemCount: roots.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final root = roots[index];
        final isExpanded = _isNodeExpanded(root, 0);
        return _RootAccordion(
          root: root,
          isExpanded: isExpanded,
          isSelected: root.id == widget.initialCategory?.id,
          duration: _expansionDuration,
          onTap: () => _toggleNode(root, tree, const []),
          children: isExpanded
              ? _buildNodeList(
                  root.children,
                  tree,
                  ancestors: <String>[root.id],
                )
              : null,
        );
      },
    );
  }

  Widget _buildNodeList(
    List<CategoryNode> nodes,
    List<CategoryNode> tree, {
    required List<String> ancestors,
  }) {
    final visibleNodes = nodes.where((node) => !_isOther(node.name)).toList();

    return Column(
      key: ValueKey('category-children-${ancestors.last}'),
      children: [
        for (var index = 0; index < visibleNodes.length; index++) ...[
          if (index > 0)
            const Divider(height: 1, thickness: 1, color: AppColors.border),
          _buildNode(
            visibleNodes[index],
            tree,
            ancestors: ancestors,
          ),
        ],
      ],
    );
  }

  Widget _buildNode(
    CategoryNode node,
    List<CategoryNode> tree, {
    required List<String> ancestors,
  }) {
    final depth = ancestors.length;
    final isExpanded = _isNodeExpanded(node, depth);
    final isSelected = node.id == widget.initialSubcategory?.id;

    return Column(
      children: [
        _CategoryRow(
          key: ValueKey('category-node-${node.id}'),
          node: node,
          depth: depth,
          isExpanded: isExpanded,
          isSelected: isSelected,
          onTap: () => _toggleNode(node, tree, ancestors),
        ),
        AnimatedSize(
          duration: _expansionDuration,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: isExpanded
              ? _buildNodeList(
                  node.children,
                  tree,
                  ancestors: <String>[...ancestors, node.id],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  bool _isNodeExpanded(CategoryNode node, int depth) {
    return node.children.isNotEmpty &&
        _expandedPath.length > depth &&
        _expandedPath[depth] == node.id;
  }

  bool _isOther(String name) {
    final normalized = name.trim().toLowerCase();
    return normalized == 'otro' ||
        normalized == 'otra' ||
        normalized == 'otros' ||
        normalized == 'otras' ||
        normalized.startsWith('otro /') ||
        normalized.startsWith('otra /') ||
        normalized.startsWith('otro (');
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildError() {
    return _SelectorState(
      icon: Icons.wifi_off_rounded,
      message: 'No pudimos cargar las categorías.',
      actionLabel: 'Reintentar',
      onAction: () => ref.invalidate(categoryTreeProvider),
    );
  }

  Widget _buildEmpty() {
    return _SelectorState(
      icon: Icons.inventory_2_outlined,
      message: 'No hay categorías disponibles en este momento.',
      actionLabel: 'Reintentar',
      onAction: () => ref.invalidate(categoryTreeProvider),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.grey300,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class _RootAccordion extends StatelessWidget {
  final CategoryNode root;
  final bool isExpanded;
  final bool isSelected;
  final Duration duration;
  final VoidCallback onTap;
  final Widget? children;

  const _RootAccordion({
    required this.root,
    required this.isExpanded,
    required this.isSelected,
    required this.duration,
    required this.onTap,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                button: true,
                selected: isSelected,
                expanded: isExpanded,
                label: root.name,
                child: Material(
                  color: isExpanded
                      ? AppColors.primaryMuted.withValues(alpha: 0.56)
                      : AppColors.surface,
                  child: InkWell(
                    key: ValueKey('category-root-${root.id}'),
                    onTap: onTap,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 60),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
                        child: Row(
                          children: [
                            Icon(
                              _categoryIcon(root.name),
                              size: 28,
                              color: isExpanded
                                  ? AppColors.primaryInk
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Text(
                                root.name,
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 24,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedSize(
                duration: duration,
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: children == null
                    ? const SizedBox.shrink()
                    : Column(
                        children: [
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.border,
                          ),
                          children!,
                        ],
                      ),
              ),
            ],
          ),
          if (isExpanded)
            const Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: ColoredBox(
                color: AppColors.primary,
                child: SizedBox(width: 3),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategoryNode node;
  final int depth;
  final bool isExpanded;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryRow({
    super.key,
    required this.node,
    required this.depth,
    required this.isExpanded,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final leftInset = 64.0 + ((depth - 1) * 20);
    return Semantics(
      button: true,
      selected: isSelected,
      expanded: node.children.isNotEmpty ? isExpanded : null,
      label: node.name,
      child: Material(
        color: isSelected
            ? AppColors.primaryMuted.withValues(alpha: 0.56)
            : AppColors.surface,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: EdgeInsets.fromLTRB(leftInset, 10, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      node.name,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 15,
                        height: 1.25,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 22,
                      color: AppColors.primary,
                    )
                  else if (node.children.isNotEmpty)
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: AppColors.textSecondary,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectorState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _SelectorState({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 15,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryInk,
                minimumSize: const Size(48, 48),
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _categoryIcon(String name) {
  final normalized = name
      .trim()
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');

  if (normalized.contains('freno')) return Icons.album_outlined;
  if (normalized.contains('motor')) return Icons.settings_outlined;
  if (normalized.contains('suspension')) return Icons.linear_scale_rounded;
  if (normalized.contains('transmision')) {
    return Icons.precision_manufacturing_outlined;
  }
  if (normalized.contains('calefaccion') || normalized.contains('a/c')) {
    return Icons.ac_unit_rounded;
  }
  if (normalized.contains('lubric')) return Icons.oil_barrel_outlined;
  if (normalized.contains('electric')) return Icons.bolt_outlined;
  if (normalized.contains('direccion')) return Icons.adjust_rounded;
  if (normalized.contains('escape')) return Icons.air_rounded;
  return Icons.build_outlined;
}
