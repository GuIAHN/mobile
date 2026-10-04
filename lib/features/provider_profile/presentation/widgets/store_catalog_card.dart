import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/catalog_summary_card.dart';
import '../../../../shared/widgets/count_pill.dart';
import '../../domain/entities/store_catalog.dart';
import '../../domain/entities/store_catalog_line.dart';
import '../providers/provider_profile_providers.dart';

/// Perfil comercial de la tienda con cobertura global y catálogo separados.
class StoreCatalogCard extends ConsumerWidget {
  const StoreCatalogCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(storeCatalogProvider);

    return Container(
      key: const Key('store-catalog-card'),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: _catalogShellDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'CATÁLOGO DE LA TIENDA',
                  style: AppTypography.overline,
                ),
              ),
              catalogAsync.maybeWhen(
                data: (catalog) => catalog.subcategories.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.sm),
                        child: CountPill(
                          count: catalog.subcategories.length,
                          textColor: AppColors.textPrimary,
                        ),
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(height: 1, color: AppColors.border),
          ),
          Text(
            'Marcas, tipos de repuesto y categorías que ofrece tu tienda.',
            style: AppTypography.bodySm,
          ),
          const SizedBox(height: AppSpacing.lg),
          catalogAsync.when(
            loading: () => const _CatalogLoading(),
            error: (error, _) => _CatalogError(
              message: _friendlyError(error),
              onRetry: () => ref.invalidate(storeCatalogProvider),
            ),
            data: (catalog) => _isCatalogEmpty(catalog)
                ? const _EmptyCatalog()
                : _CatalogContent(catalog: catalog),
          ),
        ],
      ),
    );
  }
}

class _CatalogContent extends StatelessWidget {
  const _CatalogContent({required this.catalog});

  final StoreCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final groups = _groupSubcategories(catalog.subcategories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel(
          label: 'MARCAS QUE ATIENDES',
          count: catalog.servesAllBrands ? null : catalog.brands.length,
        ),
        const SizedBox(height: AppSpacing.sm),
        _BrandsSummaryRow(
          catalog: catalog,
          onTap: () => _showBrands(context, catalog),
        ),
        const _CatalogDivider(),
        const _SectionLabel(label: 'TIPOS DE REPUESTO'),
        const SizedBox(height: AppSpacing.md),
        _PartTypesRow(types: catalog.sparePartsTypes),
        const _CatalogDivider(),
        _SectionLabel(
          label: 'CATEGORÍAS Y SUBCATEGORÍAS',
          count: catalog.subcategories.length,
        ),
        const SizedBox(height: AppSpacing.md),
        for (var index = 0; index < groups.length; index++) ...[
          if (index > 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Divider(
                height: 1,
                indent: AppSpacing.xl3 + AppSpacing.md,
                color: AppColors.border,
              ),
            ),
          _CategoryGroupView(
            key: ValueKey('store-category-${groups[index].id}'),
            group: groups[index],
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.count});

  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: AppTypography.overline)),
        if (count != null) ...[
          const SizedBox(width: AppSpacing.sm),
          CountPill(count: count!, textColor: AppColors.textPrimary),
        ],
      ],
    );
  }
}

class _CatalogDivider extends StatelessWidget {
  const _CatalogDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Divider(height: 1, color: AppColors.border),
    );
  }
}

class _BrandsSummaryRow extends StatelessWidget {
  const _BrandsSummaryRow({required this.catalog, required this.onTap});

  final StoreCatalog catalog;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final summary = _brandSummary(catalog);
    return Semantics(
      button: true,
      label: '$summary. Ver marcas atendidas.',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('store-catalog-brands'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.buttonHeightMd,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: AppSpacing.xl3,
                    child: AppLineIcon(
                      AppIcons.store,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(summary, style: AppTypography.title),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Aplica a todas las subcategorías de tu catálogo.',
                          style: AppTypography.bodySm,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Ver marcas',
                          style: AppTypography.label.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.xs),
                    child: AppLineIcon(
                      AppIcons.next,
                      size: AppIconSize.action,
                      color: AppColors.primary,
                    ),
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

class _PartTypesRow extends StatelessWidget {
  const _PartTypesRow({required this.types});

  final List<String> types;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: types.isEmpty
          ? 'Sin tipos de repuesto configurados'
          : 'Tipos de repuesto: ${types.map(catalogPartTypeLabel).join(', ')}',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: AppSpacing.xl3,
            child: AppLineIcon(
              AppIcons.offer,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: types.isEmpty
                ? Text('Sin tipos configurados', style: AppTypography.bodySm)
                : Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: types
                        .map(
                          (type) => _DetailPill(
                            label: catalogPartTypeLabel(type),
                            emphasized: true,
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGroupView extends StatefulWidget {
  const _CategoryGroupView({super.key, required this.group});

  final _CategoryGroup group;

  @override
  State<_CategoryGroupView> createState() => _CategoryGroupViewState();
}

class _CategoryGroupViewState extends State<_CategoryGroupView> {
  bool _expanded = false;

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final count = group.subcategories.length;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 220);
    final countLabel = count == 1 ? 'subcategoría' : 'subcategorías';
    final actionLabel =
        _expanded ? 'Ocultar subcategorías' : 'Mostrar subcategorías';
    final subcategories = _expanded
        ? Padding(
            key: ValueKey('store-category-content-${group.id}'),
            padding: const EdgeInsets.only(
              left: AppSpacing.xl3 + AppSpacing.md,
            ),
            child: Column(
              children: [
                for (var index = 0; index < count; index++) ...[
                  if (index > 0)
                    const Divider(height: 1, color: AppColors.border),
                  _SubcategoryRow(line: group.subcategories[index]),
                ],
              ],
            ),
          )
        : const SizedBox(width: double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _expanded,
          label: '${group.name}, $count $countLabel. $actionLabel',
          excludeSemantics: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('store-category-toggle-${group.id}'),
              onTap: _toggleExpanded,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSpacing.buttonHeightMd,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: AppSpacing.xl3,
                        child: AppLineIcon(
                          _categoryIcon(group.name),
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(group.name, style: AppTypography.title),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      CountPill(
                        count: count,
                        textColor: AppColors.textPrimary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: duration,
                        curve: Curves.easeOutCubic,
                        child: AppLineIcon(
                          AppIcons.expand,
                          size: AppIconSize.action,
                          color: _expanded
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (reduceMotion)
          subcategories
        else
          AnimatedSize(
            duration: duration,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: subcategories,
          ),
      ],
    );
  }
}

class _SubcategoryRow extends StatelessWidget {
  const _SubcategoryRow({required this.line});

  final StoreCatalogLine line;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Subcategoría ${line.subcategoryName}',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.buttonHeightMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              const AppLineIcon(
                AppIcons.selected,
                size: AppIconSize.inline,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(line.subcategoryName, style: AppTypography.body),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showBrands(BuildContext context, StoreCatalog catalog) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  return showModalBottomSheet<void>(
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
    builder: (_) => _BrandsSheet(catalog: catalog),
  );
}

class _BrandsSheet extends StatelessWidget {
  const _BrandsSheet({required this.catalog});

  final StoreCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final usesLargeText = mediaQuery.textScaler.scale(14) >= 21;

    return FractionallySizedBox(
      heightFactor: usesLargeText ? 0.96 : 0.82,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl2,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textDisabled,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: AppSpacing.xl3,
                        child: AppLineIcon(
                          AppIcons.store,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Marcas que atiendes',
                              style: AppTypography.h2,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _brandSummary(catalog),
                              style: AppTypography.bodySm,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('close-catalog-details'),
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.pop(context),
                        constraints: const BoxConstraints(
                          minWidth: AppSpacing.buttonHeightMd,
                          minHeight: AppSpacing.buttonHeightMd,
                        ),
                        icon: const AppLineIcon(
                          AppIcons.close,
                          size: AppIconSize.action,
                        ),
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(child: _BrandsList(catalog: catalog)),
          ],
        ),
      ),
    );
  }
}

class _BrandsList extends StatelessWidget {
  const _BrandsList({required this.catalog});

  final StoreCatalog catalog;

  @override
  Widget build(BuildContext context) {
    final names = catalog.servesAllBrands
        ? const ['Atiende todas las marcas disponibles']
        : catalog.brands;

    if (names.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Text(
            'No hay marcas configuradas.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySm,
          ),
        ),
      );
    }

    return ListView.separated(
      key: const Key('catalog-brands-list'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl2,
        0,
        AppSpacing.xl2,
        AppSpacing.xl2,
      ),
      itemCount: names.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        indent: AppSpacing.xl3,
        color: AppColors.border,
      ),
      itemBuilder: (_, index) => _BrandRow(name: names[index]),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: name,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.buttonHeightMd),
        child: Row(
          children: [
            const AppLineIcon(
              AppIcons.selected,
              size: AppIconSize.inline,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(name, style: AppTypography.body)),
          ],
        ),
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.label, this.emphasized = false});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: emphasized ? AppColors.primaryMuted : AppColors.grey100,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: AppTypography.meta.copyWith(
          color: emphasized ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Aún no has configurado tu catálogo de tienda',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppLineIcon(
              AppIcons.info,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Aún no has configurado tu catálogo de tienda.',
                style: AppTypography.bodySm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogLoading extends StatelessWidget {
  const _CatalogLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando catálogo de la tienda',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [0.72, 1.0, 0.88, 0.64]
            .map(
                (widthFactor) => _CatalogSkeletonLine(widthFactor: widthFactor))
            .toList(growable: false),
      ),
    );
  }
}

class _CatalogSkeletonLine extends StatelessWidget {
  const _CatalogSkeletonLine({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: AppSpacing.md,
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: AppTypography.bodySm.copyWith(color: AppColors.errorInk),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              key: const Key('retry-store-catalog'),
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.errorInk,
                minimumSize: const Size(88, AppSpacing.buttonHeightMd),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                textStyle: AppTypography.label,
              ),
              icon: const AppLineIcon(
                AppIcons.retry,
                size: AppIconSize.inline,
              ),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGroup {
  const _CategoryGroup({
    required this.id,
    required this.name,
    required this.subcategories,
  });

  final String id;
  final String name;
  final List<StoreCatalogLine> subcategories;
}

List<_CategoryGroup> _groupSubcategories(List<StoreCatalogLine> lines) {
  final grouped = <String, List<StoreCatalogLine>>{};
  final names = <String, String>{};
  for (final line in lines) {
    grouped.putIfAbsent(line.categoryId, () => []).add(line);
    names[line.categoryId] = line.categoryName;
  }
  return grouped.entries
      .map(
        (entry) => _CategoryGroup(
          id: entry.key,
          name: names[entry.key]!,
          subcategories: entry.value,
        ),
      )
      .toList(growable: false);
}

String _brandSummary(StoreCatalog catalog) {
  if (catalog.servesAllBrands) return 'Todas las marcas';
  final count = catalog.brands.length;
  if (count == 0) return 'Sin marcas seleccionadas';
  return '$count ${count == 1 ? 'marca' : 'marcas'}';
}

bool _isCatalogEmpty(StoreCatalog catalog) {
  return !catalog.servesAllBrands &&
      catalog.brands.isEmpty &&
      catalog.sparePartsTypes.isEmpty &&
      catalog.subcategories.isEmpty;
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

  if (normalized.contains('motor')) return AppIcons.engine;
  if (normalized.contains('transmision') ||
      normalized.contains('caja') ||
      normalized.contains('cambio')) {
    return AppIcons.transmission;
  }
  if (normalized.contains('suspension') || normalized.contains('direccion')) {
    return AppIcons.suspension;
  }
  if (normalized.contains('freno')) return AppIcons.brakes;
  if (normalized.contains('electric') ||
      normalized.contains('electron') ||
      normalized.contains('bateria') ||
      normalized.contains('encendido')) {
    return AppIcons.electrical;
  }
  if (normalized.contains('latoneria') ||
      normalized.contains('pintura') ||
      normalized.contains('carroceria')) {
    return AppIcons.bodywork;
  }
  if (normalized.contains('audio') || normalized.contains('multimedia')) {
    return AppIcons.audio;
  }
  if (normalized.contains('climat') ||
      normalized.contains('aire acondicionado')) {
    return AppIcons.climate;
  }
  if (normalized.contains('combustible') || normalized.contains('inyeccion')) {
    return AppIcons.fuel;
  }
  if (normalized.contains('caucho') ||
      normalized.contains('neumatic') ||
      normalized.contains('rueda') ||
      normalized.contains('rin')) {
    return AppIcons.wheels;
  }
  if (normalized.contains('iluminacion') || normalized.contains('luz')) {
    return AppIcons.lighting;
  }
  return AppIcons.catalog;
}

BoxDecoration _catalogShellDecoration() {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
    border: Border.all(color: AppColors.border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

String _friendlyError(Object error) {
  if (error is Failure) return error.message;
  return 'No pudimos cargar el catálogo de la tienda. Inténtalo nuevamente.';
}
