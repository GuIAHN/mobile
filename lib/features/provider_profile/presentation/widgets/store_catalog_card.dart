import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/catalog_summary_card.dart';
import '../../../../shared/widgets/count_pill.dart';
import '../../domain/entities/store_catalog_line.dart';
import '../providers/provider_profile_providers.dart';

/// Sección de perfil que resume la línea de venta de la tienda.
///
/// Cada categoría se presenta con el mismo card compacto del registro. Las
/// marcas completas se consultan en un bottom sheet para evitar que la sección
/// crezca varias pantallas cuando una tienda atiende muchas marcas.
class StoreCatalogCard extends ConsumerWidget {
  const StoreCatalogCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(storeCatalogProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Flexible(
              child: Text('LÍNEA DE VENTA', style: AppTypography.overline),
            ),
            catalogAsync.maybeWhen(
              data: (lines) => lines.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: CountPill(
                        count: lines.length,
                        textColor: AppColors.textPrimary,
                      ),
                    ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Categorías de repuestos que vendes y las marcas que cubres.',
          style: AppTypography.bodySm,
        ),
        const SizedBox(height: AppSpacing.lg),
        catalogAsync.when(
          loading: () => const _CatalogLoading(),
          error: (error, _) => _CatalogError(
            message: _friendlyError(error),
            onRetry: () => ref.invalidate(storeCatalogProvider),
          ),
          data: (lines) => lines.isEmpty
              ? const _EmptyCatalog()
              : Column(
                  children: [
                    for (var i = 0; i < lines.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.md),
                      CatalogSummaryCard(
                        key: ValueKey('store-catalog-line-${lines[i].id}'),
                        title: lines[i].categoryName,
                        icon: _categoryIcon(lines[i].categoryName),
                        brandSummary: _brandSummary(lines[i]),
                        sparePartTypes: lines[i].sparePartsTypes,
                        configured: _isConfigured(lines[i]),
                        actionLabel: 'Ver marcas',
                        onTap: () => _showCatalogDetails(context, lines[i]),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

Future<void> _showCatalogDetails(
  BuildContext context,
  StoreCatalogLine line,
) {
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
    builder: (_) => _CatalogDetailsSheet(line: line),
  );
}

bool _isConfigured(StoreCatalogLine line) {
  final hasBrands = line.servesAllBrands || line.brands.isNotEmpty;
  return hasBrands && line.sparePartsTypes.isNotEmpty;
}

String _brandSummary(StoreCatalogLine line) {
  if (line.servesAllBrands) return 'Todas las marcas';
  final count = line.brands.length;
  if (count == 0) return 'Sin marcas seleccionadas';
  return '$count ${count == 1 ? 'marca' : 'marcas'}';
}

IconData _categoryIcon(String name) {
  final normalized = name.toLowerCase();
  if (normalized.contains('motor')) return Icons.settings_outlined;
  if (normalized.contains('transmisión') || normalized.contains('caja')) {
    return Icons.account_tree_outlined;
  }
  if (normalized.contains('suspensión') || normalized.contains('dirección')) {
    return Icons.unfold_more_outlined;
  }
  if (normalized.contains('freno')) return Icons.album_outlined;
  if (normalized.contains('electricidad') ||
      normalized.contains('electrónico')) {
    return Icons.bolt_outlined;
  }
  if (normalized.contains('latonería') ||
      normalized.contains('pintura') ||
      normalized.contains('carrocería')) {
    return Icons.format_paint_outlined;
  }
  return Icons.build_outlined;
}

class _CatalogDetailsSheet extends StatelessWidget {
  const _CatalogDetailsSheet({required this.line});

  final StoreCatalogLine line;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final usesLargeText = mediaQuery.textScaler.scale(14) >= 21;

    return FractionallySizedBox(
      heightFactor: usesLargeText ? 0.96 : 0.82,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl2,
                AppSpacing.md,
                AppSpacing.md,
                0,
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
                      Container(
                        width: AppSpacing.iconXl,
                        height: AppSpacing.iconXl,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primaryMuted,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _categoryIcon(line.categoryName),
                          size: AppSpacing.iconMd,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(line.categoryName, style: AppTypography.h2),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _brandSummary(line),
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
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'TIPOS DE REPUESTO',
                      style: AppTypography.overline,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: line.sparePartsTypes.isEmpty
                          ? [
                              const _DetailPill(
                                label: 'Sin tipos configurados',
                                emphasized: false,
                              ),
                            ]
                          : line.sparePartsTypes
                              .map(
                                (type) => _DetailPill(
                                  label: catalogPartTypeLabel(type),
                                  emphasized: true,
                                ),
                              )
                              .toList(growable: false),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: Text('MARCAS', style: AppTypography.overline),
                      ),
                      if (!line.servesAllBrands)
                        CountPill(
                          count: line.brands.length,
                          textColor: AppColors.textPrimary,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
            Expanded(child: _BrandsList(line: line)),
          ],
        ),
      ),
    );
  }
}

class _BrandsList extends StatelessWidget {
  const _BrandsList({required this.line});

  final StoreCatalogLine line;

  @override
  Widget build(BuildContext context) {
    if (line.servesAllBrands) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl2,
          0,
          AppSpacing.xl2,
          AppSpacing.xl2,
        ),
        children: const [
          _BrandRow(
            name: 'Atiende todas las marcas disponibles',
            icon: Icons.public_rounded,
          ),
        ],
      );
    }

    if (line.brands.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Text(
            'No hay marcas configuradas para esta categoría.',
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
      itemCount: line.brands.length,
      separatorBuilder: (_, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, index) => _BrandRow(name: line.brands[index]),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow({
    required this.name,
    this.icon = Icons.check_circle_outline_rounded,
  });

  final String name;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: name,
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.buttonHeightMd),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: AppSpacing.iconSm, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(name, style: AppTypography.body)),
          ],
        ),
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.label, required this.emphasized});

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
      label: 'Aún no has configurado tu línea de venta',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.primary,
              size: AppSpacing.iconMd,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Aún no has configurado tu línea de venta.',
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
      label: 'Cargando línea de venta',
      child: Column(
        children: const [116.0, 116.0]
            .map(
              (height) => Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                width: double.infinity,
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CatalogError({required this.message, required this.onRetry});

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
            TextButton(
              key: const Key('retry-store-catalog'),
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.errorInk,
                minimumSize: const Size(88, AppSpacing.buttonHeightMd),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                textStyle: AppTypography.label,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

String _friendlyError(Object error) {
  if (error is Failure) return error.message;
  return 'No pudimos cargar tu línea de venta. Inténtalo nuevamente.';
}
