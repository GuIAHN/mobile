import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/count_pill.dart';
import '../../domain/entities/store_catalog_line.dart';
import '../providers/provider_profile_providers.dart';

/// Tarjeta de perfil que muestra la "línea de venta" de la tienda: qué
/// categorías de repuestos ofrece, para qué marcas y en qué calidad
/// (original, genérico, performance). Solo lectura, sigue el mismo patrón
/// visual que [ProviderSpecialtiesCard].
class StoreCatalogCard extends ConsumerWidget {
  const StoreCatalogCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(storeCatalogProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  'LÍNEA DE VENTA',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              catalogAsync.maybeWhen(
                data: (lines) => lines.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: CountPill(count: lines.length),
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Text(
            'Categorías de repuestos que vendes y las marcas que cubres.',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
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
                        if (i > 0)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Divider(height: 1),
                          ),
                        _CatalogLineRow(line: lines[i]),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Fila plana (sin card anidada) para una línea del catálogo: ícono +
/// nombre de categoría, seguido de un único Wrap que combina los chips de
/// tipo de repuesto y de marcas. Las filas se separan con un Divider desde
/// [StoreCatalogCard], no con bordes propios, para evitar el efecto
/// "card dentro de card".
class _CatalogLineRow extends StatelessWidget {
  final StoreCatalogLine line;

  const _CatalogLineRow({required this.line});

  @override
  Widget build(BuildContext context) {
    final hasChips =
        line.sparePartsTypes.isNotEmpty || line.servesAllBrands || line.brands.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.settings_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                line.categoryName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        if (hasChips) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...line.sparePartsTypes.map((t) => _TypeChip(type: t)),
              if (line.servesAllBrands)
                const _AllBrandsChip()
              else
                ...line.brands.map((b) => _BrandChip(name: b)),
            ],
          ),
        ],
      ],
    );
  }
}

/// Chip "Atiende todas las marcas", con el mismo tratamiento pill que el
/// resto de los chips de la fila para que se lean como parte del mismo
/// grupo en vez de un texto suelto aparte.
class _AllBrandsChip extends StatelessWidget {
  const _AllBrandsChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.celesteMuted,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.public_rounded,
            size: 14,
            color: AppColors.celesteInk,
          ),
          const SizedBox(width: 6),
          Text(
            'Todas las marcas',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.celesteInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandChip extends StatelessWidget {
  final String name;

  const _BrandChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        name,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String type;

  const _TypeChip({required this.type});

  String get _label {
    switch (type) {
      case 'ORIGINAL':
        return 'Original';
      case 'GENERIC':
        return 'Genérico';
      case 'PERFORMANCE':
        return 'Performance';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryMuted,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        _label,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Aún no has configurado tu línea de venta.',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
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
        children: const [96.0, 130.0]
            .map(
              (height) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                width: double.infinity,
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(16),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              height: 1.35,
              color: AppColors.errorInk,
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            key: const Key('retry-store-catalog'),
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorInk,
              minimumSize: const Size(88, 48),
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

String _friendlyError(Object error) {
  if (error is Failure) return error.message;
  return 'No pudimos cargar tu línea de venta. Inténtalo nuevamente.';
}
