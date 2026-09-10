import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../shared/utils/search_text_normalizer.dart';
import '../../../../catalog/domain/entities/category.dart';
import '../../../../catalog/domain/entities/category_node.dart';
import '../../../../catalog/presentation/providers/catalog_providers.dart';

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
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 320),
        reverseDuration: Duration(milliseconds: 220),
      ),
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
  List<String> _navigationPath = const [];
  bool _didInitializeNavigation = false;
  bool _navigatingForward = true;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _contentReady = false;
  Timer? _entranceTimer;

  @override
  void initState() {
    super.initState();
    _entranceTimer = Timer(const Duration(milliseconds: 340), () {
      if (mounted) setState(() => _contentReady = true);
    });
  }

  @override
  void dispose() {
    _entranceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Duration get _navigationDuration => MediaQuery.of(context).disableAnimations
      ? Duration.zero
      : const Duration(milliseconds: 220);

  void _initializeNavigation(List<CategoryNode> roots) {
    if (_didInitializeNavigation || roots.isEmpty) return;
    _didInitializeNavigation = true;

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
    if (initialRoot != null && initialRoot.children.isNotEmpty) {
      _navigationPath = <String>[initialRoot.id];
    }
  }

  void _openNode(CategoryNode node, List<CategoryNode> tree) {
    if (node.children.isEmpty) {
      _selectLeaf(node, tree);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _navigatingForward = true;
      _navigationPath = <String>[..._navigationPath, node.id];
      _searchController.clear();
      _query = '';
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
        isCatchAll: node.isCatchAll,
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

  CategoryNode? _currentNode(List<CategoryNode> tree) {
    if (_navigationPath.isEmpty) return null;

    List<CategoryNode> level = tree;
    CategoryNode? current;
    for (final id in _navigationPath) {
      current = _findDirectNode(level, id);
      if (current == null) return null;
      level = current.children;
    }
    return current;
  }

  CategoryNode? _findDirectNode(List<CategoryNode> nodes, String id) {
    for (final node in nodes) {
      if (node.id == id) return node;
    }
    return null;
  }

  CategoryNode? _activeRoot(List<CategoryNode> tree) {
    if (_navigationPath.isEmpty) return null;
    return _findDirectNode(tree, _navigationPath.first);
  }

  void _handleBack() {
    if (_query.isNotEmpty) {
      FocusScope.of(context).unfocus();
      setState(() {
        _searchController.clear();
        _query = '';
      });
      return;
    }

    if (_navigationPath.isNotEmpty) {
      setState(() {
        _navigatingForward = false;
        _navigationPath = _navigationPath.sublist(
          0,
          _navigationPath.length - 1,
        );
      });
      return;
    }
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final treeAsync = ref.watch(categoryTreeProvider);
    final mediaQuery = MediaQuery.of(context);
    final loadedTree = treeAsync.asData?.value;
    if (loadedTree != null) {
      _initializeNavigation(
        loadedTree.where((node) => !node.isCatchAll).toList(),
      );
      if (_navigationPath.isNotEmpty && _currentNode(loadedTree) == null) {
        _navigationPath = const [];
      }
    }
    final currentNode = loadedTree == null ? null : _currentNode(loadedTree);
    final activeRoot = loadedTree == null ? null : _activeRoot(loadedTree);
    final catchAll =
        activeRoot == null ? null : _findDirectCatchAll(activeRoot.children);

    return Container(
      key: const Key('category-sheet-shell'),
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
          _buildHeader(currentNode),
          const SizedBox(height: 16),
          _buildSearchField(currentNode),
          const SizedBox(height: 16),
          Expanded(
            child: AnimatedSwitcher(
              duration: mediaQuery.disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 160),
              child: !_contentReady
                  ? const _CategorySheetWarmup(
                      key: Key('category-sheet-warmup'),
                    )
                  : KeyedSubtree(
                      key: const Key('category-sheet-content'),
                      child: treeAsync.when(
                        loading: _buildLoading,
                        error: (_, __) => _buildError(),
                        data: (tree) => _query.trim().length < 2
                            ? _buildNavigation(tree)
                            : _buildSearchResults(tree),
                      ),
                    ),
            ),
          ),
          if (_contentReady && activeRoot != null && catchAll != null) ...[
            const SizedBox(height: 12),
            _CatchAllAction(
              categoryName: activeRoot.name,
              onTap: () => _selectLeaf(catchAll, loadedTree!),
            ),
          ],
        ],
      ),
    );
  }

  CategoryNode? _findDirectCatchAll(List<CategoryNode> nodes) {
    for (final node in nodes) {
      if (node.isCatchAll) return node;
    }
    return null;
  }

  Widget _buildSearchField(CategoryNode? currentNode) {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _query = value),
      textInputAction: TextInputAction.search,
      style: AppTypography.body,
      decoration: InputDecoration(
        hintText: currentNode == null
            ? 'Buscar pieza o categoría'
            : 'Buscar en ${currentNode.name}',
        hintStyle: AppTypography.body.copyWith(
          color: AppColors.textPlaceholder,
        ),
        prefixIcon: const Icon(
          AppIcons.search,
          color: AppColors.textSecondary,
          size: AppIconSize.action,
        ),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpiar búsqueda',
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
                icon: const Icon(AppIcons.close, size: AppIconSize.action),
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
    final normalized = normalizeSearchText(_query);
    final results = <_CategorySearchResult>[];
    final currentNode = _currentNode(tree);
    final scopes = currentNode == null
        ? tree.where((node) => !node.isCatchAll)
        : <CategoryNode>[currentNode];
    final leadingPath = _navigationPathNames(tree);

    for (final root in scopes) {
      _collectSearchResults(
        root,
        currentNode == null ? <String>[root.name] : leadingPath,
        normalized,
        results,
      );
    }

    if (results.isEmpty) {
      return const _SelectorState(
        icon: AppIcons.searchEmpty,
        message: 'No encontramos esa pieza.\n\nAbre la categoría del sistema '
            'al que pertenece (frenos, motor, eléctrico…) y elige '
            'la opción “No encuentro la pieza…” ubicada al final.',
      );
    }

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: results.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, index) {
        final result = results[index];
        return Material(
          color: Colors.transparent,
          child: ListTile(
            minTileHeight: 64,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: AppLineIcon(
              _categoryIcon(result.node.name),
              color: AppColors.textSecondary,
            ),
            title: Text(result.node.name, style: AppTypography.title),
            subtitle: Text(
              result.breadcrumb,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySm,
            ),
            trailing: const Icon(AppIcons.next, size: AppIconSize.action),
            onTap: () => _selectLeaf(result.node, tree),
          ),
        );
      },
    );
  }

  List<String> _navigationPathNames(List<CategoryNode> tree) {
    final names = <String>[];
    var level = tree;
    for (final id in _navigationPath) {
      final node = _findDirectNode(level, id);
      if (node == null) break;
      names.add(node.name);
      level = node.children;
    }
    return names;
  }

  void _collectSearchResults(
    CategoryNode node,
    List<String> path,
    String query,
    List<_CategorySearchResult> results,
  ) {
    if (node.children.isEmpty &&
        (normalizeSearchText(node.name).contains(query) ||
            normalizeSearchText(path.join(' ')).contains(query))) {
      results.add(_CategorySearchResult(node: node, path: path));
    }
    for (final child in node.children.where((item) => !item.isCatchAll)) {
      _collectSearchResults(
        child,
        <String>[...path, child.name],
        query,
        results,
      );
    }
  }

  Widget _buildHeader(CategoryNode? currentNode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _handleBack,
          tooltip: 'Volver',
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          icon: const Icon(
            AppIcons.back,
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
                currentNode == null
                    ? 'CATÁLOGO DE PIEZAS'
                    : 'CATEGORÍA SELECCIONADA',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textMeta,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                currentNode?.name ?? 'Busca tu repuesto',
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
            AppIcons.close,
            size: AppIconSize.leading,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigation(List<CategoryNode> tree) {
    final roots = tree.where((node) => !node.isCatchAll).toList();
    if (roots.isEmpty) {
      return _buildEmpty();
    }

    final currentNode = _currentNode(tree);
    final visibleNodes = (currentNode?.children ?? roots)
        .where((node) => !node.isCatchAll)
        .toList();
    final viewKey = currentNode?.id ?? 'root';

    final Widget content;
    if (visibleNodes.isEmpty) {
      content = const _SelectorState(
        icon: AppIcons.catalog,
        message: 'No hay piezas específicas en esta categoría.',
      );
    } else {
      content = ListView.separated(
        padding: const EdgeInsets.only(bottom: 4),
        physics: const BouncingScrollPhysics(),
        itemCount: visibleNodes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final node = visibleNodes[index];
          final isRoot = currentNode == null;
          return _CategoryNavigationRow(
            key: ValueKey(
              isRoot ? 'category-root-${node.id}' : 'category-node-${node.id}',
            ),
            node: node,
            isRoot: isRoot,
            isSelected: node.id == widget.initialSubcategory?.id,
            onTap: () => _openNode(node, tree),
          );
        },
      );
    }

    return AnimatedSwitcher(
      duration: _navigationDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        if (_navigationDuration == Duration.zero) return child;
        final offset = _navigatingForward ? 0.08 : -0.08;
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(offset, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey('category-view-$viewKey'),
        child: content,
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildError() {
    return _SelectorState(
      icon: AppIcons.connectivityError,
      message: 'No pudimos cargar las categorías.',
      actionLabel: 'Reintentar',
      onAction: () => ref.invalidate(categoryTreeProvider),
    );
  }

  Widget _buildEmpty() {
    return _SelectorState(
      icon: AppIcons.catalog,
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

class _CategorySheetWarmup extends StatelessWidget {
  const _CategorySheetWarmup({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) => Container(
        height: 60,
        decoration: BoxDecoration(
          color: index == 0 ? AppColors.primaryMuted : AppColors.grey100,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _CategoryNavigationRow extends StatelessWidget {
  final CategoryNode node;
  final bool isRoot;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryNavigationRow({
    super.key,
    required this.node,
    required this.isRoot,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: node.children.isEmpty
          ? '${node.name}, seleccionar pieza'
          : '${node.name}, abrir categoría',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: isRoot ? 64 : 56),
            child: Ink(
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryMuted.withValues(alpha: 0.56)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 1.4 : 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  if (isRoot)
                    AppLineIcon(
                      _categoryIcon(node.name),
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    )
                  else
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.primary : AppColors.grey300,
                        shape: BoxShape.circle,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      node.name,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: isRoot ? 16 : 15,
                        height: 1.25,
                        fontWeight: isSelected || isRoot
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (isSelected && node.children.isEmpty)
                    const Icon(
                      AppIcons.selected,
                      size: AppIconSize.action,
                      color: AppColors.primary,
                    )
                  else if (node.children.isNotEmpty)
                    const Icon(
                      AppIcons.next,
                      size: AppIconSize.action,
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

class _CatchAllAction extends StatelessWidget {
  final String categoryName;
  final VoidCallback onTap;

  const _CatchAllAction({
    required this.categoryName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = 'No encuentro la pieza en $categoryName';
    return Semantics(
      button: true,
      label: '$label. Seleccionar otra pieza de $categoryName',
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          key: ValueKey('category-catch-all-action-$categoryName'),
          onPressed: onTap,
          icon: const Icon(
            AppIcons.question,
            size: AppIconSize.action,
            color: AppColors.primary,
          ),
          label: Text(
            label,
            textAlign: TextAlign.center,
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            minimumSize: const Size.fromHeight(52),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: const StadiumBorder(),
            textStyle: GoogleFonts.hankenGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w700,
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
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SelectorState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
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
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryInk,
                  minimumSize: const Size(48, 48),
                ),
                child: Text(actionLabel!),
              ),
            ],
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
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n');

  if (normalized.contains('filtro')) return AppIcons.engine;
  if (normalized.contains('pastilla') ||
      normalized.contains('disco') ||
      normalized.contains('freno')) {
    return AppIcons.brakes;
  }
  if (normalized.contains('bateria') ||
      normalized.contains('sensor') ||
      normalized.contains('modulo') ||
      normalized.contains('electronico') ||
      normalized.contains('arranque') ||
      normalized.contains('cable') ||
      normalized.contains('conexion') ||
      normalized.contains('electric') ||
      normalized.contains('encendido')) {
    return AppIcons.electrical;
  }
  if (normalized.contains('inyeccion') || normalized.contains('combustible')) {
    return AppIcons.fuel;
  }
  if (normalized.contains('iluminacion')) return AppIcons.lighting;
  if (normalized.contains('caucho') ||
      normalized.contains('neumatic') ||
      normalized.contains('rin')) {
    return AppIcons.wheels;
  }
  if (normalized.contains('altavoz') ||
      normalized.contains('transductor') ||
      normalized.contains('amplificacion') ||
      normalized.contains('procesamiento') ||
      normalized.contains('multimedia') ||
      normalized.contains('conectividad') ||
      normalized.contains('unidad central') ||
      normalized.contains('audio')) {
    return AppIcons.audio;
  }
  if (normalized.contains('aire') ||
      normalized.contains('ventilacion') ||
      normalized.contains('climatizacion')) {
    return AppIcons.climate;
  }
  if (normalized.contains('columna') ||
      normalized.contains('cardan') ||
      normalized.contains('barra') ||
      normalized.contains('terminal') ||
      normalized.contains('direccion') ||
      normalized.contains('volante')) {
    return AppIcons.transmission;
  }
  if (normalized.contains('tren') ||
      normalized.contains('amortigu') ||
      normalized.contains('suspension')) {
    return AppIcons.suspension;
  }
  if (normalized.contains('caja') || normalized.contains('transmision')) {
    return AppIcons.transmission;
  }
  if (normalized.contains('motor') || normalized.contains('interno')) {
    return AppIcons.engine;
  }
  if (normalized.contains('carroceria') ||
      normalized == 'externa' ||
      normalized == 'interna') {
    return AppIcons.bodywork;
  }
  if (normalized.contains('lubric') || normalized.contains('aceite')) {
    return AppIcons.engine;
  }
  if (normalized.contains('escape')) return AppIcons.climate;
  return AppIcons.catalog;
}
