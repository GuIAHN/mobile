import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/async_error_listener.dart';
import '../../../../core/utils/media_url.dart';
import '../../../vehicles/domain/entities/brand.dart';
import '../../../vehicles/presentation/providers/vehicle_providers.dart';
import 'store_catalog_helper.dart';

typedef StoreCoverageChanged = void Function(
  Set<Brand> brands,
  Set<String> sparePartsTypes,
  bool servesAllBrands,
);

class StoreSummaryStep extends ConsumerStatefulWidget {
  const StoreSummaryStep({
    super.key,
    required this.catalogo,
    required this.servesAllBrands,
    required this.onChanged,
  });

  final List<LineaCatalogo> catalogo;
  final bool servesAllBrands;
  final StoreCoverageChanged onChanged;

  @override
  ConsumerState<StoreSummaryStep> createState() => _StoreSummaryStepState();
}

class _StoreSummaryStepState extends ConsumerState<StoreSummaryStep> {
  static const _initialBrandLimit = 9;
  static const _partTypes = <(String, String)>[
    ('ORIGINAL', 'OEM'),
    ('GENERIC', 'Genérico'),
    ('PERFORMANCE', 'Alto\nrendimiento'),
  ];

  final _searchController = TextEditingController();
  String _query = '';
  bool _showAllBrands = false;

  Set<Brand> get _selectedBrands =>
      widget.catalogo.isEmpty ? <Brand>{} : widget.catalogo.first.brands;

  Set<String> get _selectedTypes => widget.catalogo.isEmpty
      ? <String>{}
      : widget.catalogo.first.sparePartsTypes;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _allBrandsSelected(List<Brand> allBrands) {
    if (allBrands.isEmpty || !widget.servesAllBrands) return false;
    final selectedIds = _selectedBrands.map((brand) => brand.id).toSet();
    return allBrands.every((brand) => selectedIds.contains(brand.id));
  }

  void _toggleBrand(Brand brand, List<Brand> allBrands) {
    final brands = Set<Brand>.of(_selectedBrands);
    final selected = brands.any((item) => item.id == brand.id);
    if (selected) {
      brands.removeWhere((item) => item.id == brand.id);
    } else {
      brands.add(brand);
    }
    final allSelected =
        allBrands.isNotEmpty && brands.length == allBrands.length;
    widget.onChanged(brands, Set.of(_selectedTypes), allSelected);
  }

  void _toggleAllBrands(List<Brand> allBrands) {
    final allSelected = _allBrandsSelected(allBrands);
    widget.onChanged(
      allSelected ? <Brand>{} : Set<Brand>.of(allBrands),
      Set.of(_selectedTypes),
      !allSelected,
    );
  }

  void _toggleType(String value) {
    final types = Set<String>.of(_selectedTypes);
    if (!types.remove(value)) types.add(value);
    widget.onChanged(Set.of(_selectedBrands), types, widget.servesAllBrands);
  }

  @override
  Widget build(BuildContext context) {
    ref.listenAsyncError(brandsProvider, context);
    final brandsAsync = ref.watch(brandsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionIntro(label: 'TIPOS DE REPUESTO'),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final tileHeight =
                62 + ((textScale - 1).clamp(0, 2) * 20).toDouble();
            Widget tile((String, String) type) => _ChoiceTile(
                  key: Key('spare-part-type-${type.$1}'),
                  label: type.$2,
                  selected: _selectedTypes.contains(type.$1),
                  onTap: () => _toggleType(type.$1),
                );

            if (constraints.maxWidth >= 300 && textScale < 1.6) {
              return SizedBox(
                height: tileHeight,
                child: Row(
                  children: [
                    for (var index = 0;
                        index < _partTypes.length;
                        index++) ...[
                      if (index > 0) const SizedBox(width: 8),
                      Expanded(child: tile(_partTypes[index])),
                    ],
                  ],
                ),
              );
            }

            return Column(
              children: [
                for (var index = 0; index < _partTypes.length; index++) ...[
                  if (index > 0) const SizedBox(height: 10),
                  SizedBox(
                    height: tileHeight,
                    width: constraints.maxWidth,
                    child: tile(_partTypes[index]),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        const _SectionIntro(label: 'MARCAS'),
        const SizedBox(height: 12),
        TextField(
          key: const Key('store-brand-search'),
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value.trim()),
          textInputAction: TextInputAction.search,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Buscar marca',
            hintStyle: GoogleFonts.hankenGrotesk(
              fontSize: 16,
              color: AppColors.textDisabled,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.all(14),
              child: AppLineIcon(
                AppIcons.search,
                size: AppIconSize.action,
                color: AppColors.textSecondary,
              ),
            ),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpiar búsqueda',
                    constraints:
                        const BoxConstraints.tightFor(width: 48, height: 48),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    icon: const AppLineIcon(
                      AppIcons.close,
                      size: AppIconSize.action,
                      color: AppColors.textSecondary,
                    ),
                  ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        brandsAsync.when(
          loading: () => const _BrandsState.loading(),
          error: (_, __) => _BrandsState.error(
            onRetry: () => ref.invalidate(brandsProvider),
          ),
          data: (allBrands) {
            if (allBrands.isEmpty) return const _BrandsState.empty();

            final normalizedQuery = _query.toLowerCase();
            final filtered = allBrands
                .where((brand) =>
                    brand.name.toLowerCase().contains(normalizedQuery))
                .toList();
            if (filtered.isEmpty) {
              return _BrandsState.noResults(query: _query);
            }

            final visible = _query.isNotEmpty || _showAllBrands
                ? filtered
                : filtered.take(_initialBrandLimit).toList();
            final hiddenCount = filtered.length - visible.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_query.isEmpty) ...[
                  _AllBrandsTile(
                    selected: _allBrandsSelected(allBrands),
                    onTap: () => _toggleAllBrands(allBrands),
                  ),
                  const SizedBox(height: 10),
                ],
                LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    final columns =
                        constraints.maxWidth >= 330 && textScale < 1.35
                            ? 3
                            : constraints.maxWidth >= 280
                                ? 2
                                : 1;
                    final tileHeight =
                        102 + ((textScale - 1).clamp(0, 2) * 34).toDouble();
                    return GridView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: visible.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        mainAxisExtent: tileHeight,
                      ),
                      itemBuilder: (context, index) {
                        final brand = visible[index];
                        return _BrandTile(
                          key: Key('store-brand-${brand.id}'),
                          brand: brand,
                          selected: !widget.servesAllBrands &&
                              _selectedBrands
                                  .any((item) => item.id == brand.id),
                          onTap: () => _toggleBrand(brand, allBrands),
                        );
                      },
                    );
                  },
                ),
                if (_query.isEmpty && hiddenCount > 0) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    key: const Key('show-all-store-brands'),
                    onPressed: () => setState(() => _showAllBrands = true),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: AppColors.primary,
                      textStyle: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: Text('VER $hiddenCount MARCAS MÁS'),
                  ),
                ],
                if (_query.isEmpty &&
                    _showAllBrands &&
                    allBrands.length > _initialBrandLimit) ...[
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => setState(() => _showAllBrands = false),
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: const Text('MOSTRAR MENOS'),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.hankenGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
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
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryMuted : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13.5,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: selected ? 1 : 0,
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 150),
                    child: const AppLineIcon(
                      AppIcons.selected,
                      size: AppIconSize.inline,
                      color: AppColors.primary,
                    ),
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

class _AllBrandsTile extends StatelessWidget {
  const _AllBrandsTile({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      key: const Key('toggle-all-brands'),
      button: true,
      selected: selected,
      label: 'Todas las marcas',
      onTapHint: selected ? 'Quitar selección' : 'Seleccionar',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryMuted : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                AppLineIcon(
                  AppIcons.vehicle,
                  size: AppIconSize.leading,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Todas las marcas',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
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

class _BrandTile extends StatelessWidget {
  const _BrandTile({
    super.key,
    required this.brand,
    required this.selected,
    required this.onTap,
  });

  final Brand brand;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      button: true,
      selected: selected,
      label: brand.name,
      onTapHint: selected ? 'Quitar selección' : 'Seleccionar',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 96),
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryMuted : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _BrandLogo(brand: brand),
                      const SizedBox(height: 8),
                      Text(
                        brand.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13,
                          height: 1.1,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: selected ? 1 : 0,
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 150),
                    child: const AppLineIcon(
                      AppIcons.selected,
                      size: AppIconSize.inline,
                      color: AppColors.primary,
                    ),
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

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.brand});

  final Brand brand;

  @override
  Widget build(BuildContext context) {
    final url = resolveMediaUrl(brand.photoUrl);
    const fallback = AppLineIcon(
      AppIcons.vehicle,
      size: AppIconSize.feature,
      color: AppColors.textDisabled,
    );

    Widget logo = fallback;
    if (url != null) {
      final isSvg = Uri.tryParse(url)?.path.toLowerCase().endsWith('.svg') ??
          url.toLowerCase().endsWith('.svg');
      if (isSvg) {
        logo = SvgPicture.network(
          url,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => fallback,
          errorBuilder: (_, __, ___) => fallback,
        );
      } else {
        logo = Image.network(
          url,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) return child;
            return fallback;
          },
          errorBuilder: (_, __, ___) => fallback,
        );
      }
    }

    return ExcludeSemantics(
      child: SizedBox.square(
        key: Key('store-brand-logo-${brand.id}'),
        dimension: AppIconSize.feature,
        child: logo,
      ),
    );
  }
}

class _BrandsState extends StatelessWidget {
  const _BrandsState.loading()
      : message = 'Cargando marcas…',
        icon = null,
        onRetry = null;
  const _BrandsState.empty()
      : message = 'No hay marcas disponibles en este momento.',
        icon = AppIcons.catalog,
        onRetry = null;
  const _BrandsState.noResults({required String query})
      : message = 'No encontramos marcas para “$query”.',
        icon = AppIcons.search,
        onRetry = null;
  const _BrandsState.error({required this.onRetry})
      : message = 'No pudimos cargar las marcas.',
        icon = AppIcons.cloudError;

  final String message;
  final IconData? icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
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
              AppLineIcon(
                icon!,
                size: AppIconSize.feature,
                color: AppColors.textSecondary,
              ),
            const SizedBox(height: 10),
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
              const SizedBox(height: 10),
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
    );
  }
}
