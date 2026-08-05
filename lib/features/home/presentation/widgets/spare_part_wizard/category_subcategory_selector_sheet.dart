import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../catalog/domain/entities/category.dart';
import '../../../../catalog/domain/entities/category_node.dart';
import '../../../../catalog/domain/entities/category_search_result.dart';
import '../../../../catalog/presentation/providers/catalog_providers.dart';

class CategorySubcategoryResult {
  final Category category;
  final Category subcategory;

  const CategorySubcategoryResult({
    required this.category,
    required this.subcategory,
  });
}

class _ShimmerSkeleton extends StatelessWidget {
  const _ShimmerSkeleton();
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

class CategorySubcategorySelectorSheet extends ConsumerStatefulWidget {
  static Future<CategorySubcategoryResult?> show(BuildContext context, {Category? initialCategory, Category? initialSubcategory}) {
    return showModalBottomSheet<CategorySubcategoryResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => CategorySubcategorySelectorSheet(
        initialCategory: initialCategory,
        initialSubcategory: initialSubcategory,
      ),
    );
  }

  final Category? initialCategory;
  final Category? initialSubcategory;

  const CategorySubcategorySelectorSheet({
    this.initialCategory,
    this.initialSubcategory,
  });

  @override
  ConsumerState<CategorySubcategorySelectorSheet> createState() =>
      CategorySubcategorySelectorSheetState();
}

class CategorySubcategorySelectorSheetState
    extends ConsumerState<CategorySubcategorySelectorSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _isDebouncing = false;
  // Navegación de nivel: null = mostrar raíces, != null = mostrar hijos de ese nodo
  _CategoryNodeNav? _navNode;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String val) {
    // Reset nav when user starts typing
    if (_navNode != null && val.isNotEmpty) {
      setState(() => _navNode = null);
    }
    final trimmed = val.trim();
    if (trimmed.length < 2) {
      setState(() {
        _query = '';
        _isDebouncing = false;
      });
      return;
    }

    setState(() => _isDebouncing = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _query = trimmed;
        _isDebouncing = false;
      });
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _query = '';
      _isDebouncing = false;
    });
  }

  /// Resolves the selection to (category, subcategory) and pops.
  /// If [node] has children, it's a parent/intermediate category → navigate into it to select subcategories.
  /// Only leaf nodes (nodes without children) can be selected as final subcategories.
  void _onNodeTapped(CategoryNode node, List<CategoryNode> tree, {bool fromSearch = false}) {
    if (node.children.isNotEmpty) {
      // Navigate one level deeper to show subcategories
      setState(() {
        _navNode = _CategoryNodeNav(node: node, parent: _navNode);
        _query = '';
        _searchController.clear();
      });
      return;
    }

    // Resolve parent category + subcategory for the form contract
    final Category category;
    final Category subcategory;

    if (node.parentId == null) {
      // Root with no children selected directly — treat as both cat and subcat
      category = Category(id: node.id, name: node.name);
      subcategory = Category(id: node.id, name: node.name, parentId: null);
    } else {
      // Find root ancestor to use as category
      final root = _findRoot(tree, node);
      category = Category(id: root.id, name: root.name);
      subcategory = Category(id: node.id, name: node.name, parentId: node.parentId);
    }

    Navigator.pop(
      context,
      CategorySubcategoryResult(category: category, subcategory: subcategory),
    );
  }

  CategoryNode _findRoot(List<CategoryNode> tree, CategoryNode target) {
    for (final root in tree) {
      if (root.id == target.id) return root;
      final found = _findInChildren(root, target);
      if (found != null) return root;
    }
    return target;
  }

  CategoryNode? _findInChildren(CategoryNode current, CategoryNode target) {
    if (current.id == target.id) return current;
    for (final child in current.children) {
      final found = _findInChildren(child, target);
      if (found != null) return found;
    }
    return null;
  }

  void _onOtroSelected() {
    const otroCategory = Category(id: 'f4ff2288-c7bc-4c42-b0ee-0e66a46e0395', name: 'Otro');
    Navigator.pop(
      context,
      const CategorySubcategoryResult(
        category: otroCategory,
        subcategory: Category(
          id: '4340eca0-6410-414c-9655-e91711666860',
          name: 'Otro',
          parentId: 'f4ff2288-c7bc-4c42-b0ee-0e66a46e0395',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final treeAsync = ref.watch(categoryTreeProvider);
    final searchUseCase = ref.watch(searchCategoriesUseCaseProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 26,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ───────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),

          // ── Header ───────────────────────────────────────────────────────
          Row(
            children: [
              if (_navNode != null) ...[
                GestureDetector(
                  onTap: () => setState(() {
                    _navNode = _navNode?.parent;
                    _query = '';
                    _searchController.clear();
                  }),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 12, top: 4, bottom: 4),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
              Expanded(
                child: Text(
                  _navNode != null ? _navNode!.node.name : 'Categoría de Repuesto',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Barra de búsqueda ────────────────────────────────────────────
          TextField(
            controller: _searchController,
            onChanged: _onQueryChanged,
            autofocus: false,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14.5,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Buscar categoría o subcategoría...',
              hintStyle: GoogleFonts.hankenGrotesk(
                color: AppColors.textDisabled,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? _isDebouncing
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: _clearSearch,
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Contenido principal ──────────────────────────────────────────
          Expanded(
            child: treeAsync.when(
              loading: () => _buildSkeleton(),
              error: (err, _) => _buildError(() => ref.invalidate(categoryTreeProvider)),
              data: (tree) {
                final rawText = _searchController.text.trim();
                if (rawText.length == 1) {
                  return _buildEmptyState(
                    'Ingresa al menos 2 caracteres para iniciar la búsqueda.',
                  );
                }

                // En modo búsqueda activa
                if (_query.isNotEmpty) {
                  final results = searchUseCase.call(tree, _query);
                  return _buildSearchResults(results, tree);
                }

                // En modo navegación de nodo
                if (_navNode != null) {
                  return _buildNodeChildren(_navNode!.node.children, tree);
                }

                // Estado inicial: mostrar raíces
                return _buildRootGrid(tree);
              },
            ),
          ),

          const SizedBox(height: 12),

          // ── Botón "Otro" (siempre visible) ────────────────────────────────
          Semantics(
            button: true,
            label: 'Otro / no encuentro mi categoría',
            child: Material(
              color: AppColors.primaryMuted,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _onOtroSelected,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Otro / no encuentro mi categoría',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isOtroCategoryNode(String name) {
    final n = name.trim().toLowerCase();
    return n == 'otro' ||
        n == 'otra' ||
        n == 'otros' ||
        n == 'otras' ||
        n.startsWith('otro /') ||
        n.startsWith('otra /') ||
        n.startsWith('otro (');
  }

  // ── Grid de categorías raíz ──────────────────────────────────────────────
  Widget _buildRootGrid(List<CategoryNode> tree) {
    final filteredTree = tree
        .where((node) => !_isOtroCategoryNode(node.name))
        .toList();

    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.8,
      ),
      itemCount: filteredTree.length,
      itemBuilder: (_, i) {
        final node = filteredTree[i];
        final isActive = node.id == widget.initialCategory?.id;
        return _RootCategoryTile(
          node: node,
          isActive: isActive,
          onTap: () => _onNodeTapped(node, tree),
        );
      },
    );
  }

  // ── Hijos de un nodo de navegación ──────────────────────────────────────
  Widget _buildNodeChildren(List<CategoryNode> children, List<CategoryNode> tree) {
    final filteredChildren = children
        .where((node) => !_isOtroCategoryNode(node.name))
        .toList();

    if (filteredChildren.isEmpty) {
      return _buildEmptyState('Esta categoría no tiene subcategorías.');
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: filteredChildren.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
      itemBuilder: (_, i) {
        final node = filteredChildren[i];
        final isActive = node.id == widget.initialSubcategory?.id;
        return _CategoryResultTile(
          name: node.name,
          breadcrumbLabel: '',
          isActive: isActive,
          hasChildren: node.children.isNotEmpty,
          query: '',
          onTap: () => _onNodeTapped(node, tree),
        );
      },
    );
  }

  Widget _buildSearchResults(List<CategorySearchResult> results, List<CategoryNode> tree) {
    // Filter: hide items named 'Otro'/'Otra'
    final filtered = results
        .where((r) => !_isOtroCategoryNode(r.node.name))
        .toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(
        'No se encontraron resultados para "$_query".\nPuedes usar "Otro" si no encuentras tu categoría.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Contador de resultados
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Padding(
            key: ValueKey(filtered.length),
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${filtered.length} resultado${filtered.length != 1 ? 's' : ''}',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
            itemBuilder: (_, i) {
              final r = filtered[i];
              final isActive = r.node.id == widget.initialSubcategory?.id;
              return _CategoryResultTile(
                name: r.node.name,
                breadcrumbLabel: r.breadcrumbLabel,
                isActive: isActive,
                hasChildren: r.node.children.isNotEmpty,
                query: _query,
                onTap: () => _onNodeTapped(r.node, tree, fromSearch: true),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Skeleton loader ──────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return const _ShimmerSkeleton();
  }

  // ── Error state ──────────────────────────────────────────────────────────
  Widget _buildError(VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            'Error al cargar las categorías',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(
              'Reintentar',
              style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700),
            ),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────
  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tile de categoría raíz (grid) ─────────────────────────────────────────
class _RootCategoryTile extends StatefulWidget {
  final CategoryNode node;
  final bool isActive;
  final VoidCallback onTap;

  const _RootCategoryTile({
    required this.node,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_RootCategoryTile> createState() => _RootCategoryTileState();
}

class _RootCategoryTileState extends State<_RootCategoryTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isActive ? AppColors.primaryMuted : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isActive ? AppColors.primary : AppColors.border,
              width: widget.isActive ? 1.5 : 1.0,
            ),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.node.name,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    fontWeight: widget.isActive ? FontWeight.w800 : FontWeight.w600,
                    color: widget.isActive ? AppColors.primary : AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.node.children.isNotEmpty)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: widget.isActive ? AppColors.primary : AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tile de resultado de búsqueda / hijo de nodo ──────────────────────────
class _CategoryResultTile extends StatelessWidget {
  final String name;
  final String breadcrumbLabel;
  final bool isActive;
  final bool hasChildren;
  final String query;
  final VoidCallback onTap;

  const _CategoryResultTile({
    required this.name,
    required this.breadcrumbLabel,
    required this.isActive,
    required this.hasChildren,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HighlightedText(
                    text: name,
                    query: query,
                    baseStyle: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      color: isActive ? AppColors.primary : AppColors.textPrimary,
                    ),
                    highlightStyle: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  if (breadcrumbLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.subdirectory_arrow_right_rounded,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            breadcrumbLabel,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isActive)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20)
            else
              Icon(
                hasChildren
                    ? Icons.chevron_right_rounded
                    : Icons.arrow_forward_ios_rounded,
                color: AppColors.textSecondary,
                size: hasChildren ? 20 : 14,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Widget para texto con highlights ─────────────────────────────────────
class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle baseStyle;
  final TextStyle highlightStyle;

  const _HighlightedText({
    required this.text,
    required this.query,
    required this.baseStyle,
    required this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: baseStyle);
    }
    final lower = text.toLowerCase();
    final queryLower = query.toLowerCase();
    final index = lower.indexOf(queryLower);
    if (index == -1) {
      return Text(text, style: baseStyle);
    }

    return RichText(
      text: TextSpan(children: [
        if (index > 0)
          TextSpan(text: text.substring(0, index), style: baseStyle),
        TextSpan(
          text: text.substring(index, index + query.length),
          style: highlightStyle,
        ),
        if (index + query.length < text.length)
          TextSpan(
            text: text.substring(index + query.length),
            style: baseStyle,
          ),
      ]),
    );
  }
}

// ── Helper de navegación ──────────────────────────────────────────────────
class _CategoryNodeNav {
  final CategoryNode node;
  final _CategoryNodeNav? parent;
  const _CategoryNodeNav({required this.node, this.parent});
}

// ── Alias tipado para resultados de búsqueda ──────────────────────────────
