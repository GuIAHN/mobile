import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../../domain/entities/home_filters.dart';
import '../../domain/entities/sort_option.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../../../shared/widgets/app_chip.dart';

class FiltersSheet extends ConsumerStatefulWidget {
  final HomeFilters initialFilters;
  final ServiceType serviceType;

  const FiltersSheet({
    super.key,
    required this.initialFilters,
    required this.serviceType,
  });

  @override
  ConsumerState<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends ConsumerState<FiltersSheet> {
  late HomeFilters _tempFilters;

  @override
  void initState() {
    super.initState();
    _tempFilters = widget.initialFilters;
  }

  bool get _isProviderSearch =>
      widget.serviceType == ServiceType.mechanic ||
      widget.serviceType == ServiceType.workshops;

  @override
  Widget build(BuildContext context) {
    final hasChanges = _tempFilters != const HomeFilters();
    final activeCount = _tempFilters.activeCount;
    final mq = MediaQuery.of(context);

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: mq.size.height * 0.88,
            maxWidth: mq.size.width,
          ),
        child: Material(
          color: Colors.white,
          borderRadius: AppDecorations.sheet,
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              top: AppSpacing.md,
              bottom: mq.viewInsets.bottom + AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Drag Handle ──────────────────────────────────────────
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),

                // ── Header ───────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryMuted,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: AppColors.primaryInk,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Filtros', style: AppTypography.h2),
                              if (activeCount > 0)
                                Text(
                                  '$activeCount filtro${activeCount > 1 ? 's' : ''} activo${activeCount > 1 ? 's' : ''}',
                                  style: AppTypography.meta.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryInk,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        ],
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Cerrar filtros',
                      excludeSemantics: true,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        color: AppColors.textSecondary,
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.grey100,
                          minimumSize: const Size(44, 44),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Scrollable Content ───────────────────────────────────
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Ordenar por ──────────────────────────────────
                        _buildLabel('ORDENAR POR', Icons.swap_vert_rounded),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: SortOption.values.map((option) {
                            final isSelected = _tempFilters.sortBy == option;
                            return AppChip(
                              label: option.label,
                              selected: isSelected,
                              onTap: () => setState(() => _tempFilters =
                                  _tempFilters.copyWith(sortBy: option)),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // ── Radio de búsqueda ────────────────────────────
                        if (_isProviderSearch) ...[
                          _buildLabel(
                              'RADIO DE BÚSQUEDA', Icons.radar_rounded),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [5.0, 10.0, 20.0, 30.0, 50.0].map((km) {
                              final isSelected = _tempFilters.radioKm == km;
                              return AppChip(
                                label: '${km.toInt()} km',
                                selected: isSelected,
                                onTap: () => setState(() => _tempFilters =
                                    _tempFilters.copyWith(radioKm: km)),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // ── Valoración mínima ────────────────────────────
                        _buildLabel(
                            'VALORACIÓN MÍNIMA', Icons.star_border_rounded),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [0.0, 3.0, 4.0, 4.5].map((rating) {
                            final isSelected =
                                _tempFilters.minRating == rating;
                            return AppChip(
                              label: rating == 0.0 ? 'Todas' : '$rating+ ★',
                              selected: isSelected,
                              onTap: () => setState(() => _tempFilters =
                                  _tempFilters.copyWith(minRating: rating)),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // ── Especialidades ───────────────────────────────
                        if (_isProviderSearch) ...[
                          _buildLabel('ESPECIALIDADES',
                              Icons.build_circle_outlined),
                          const SizedBox(height: 10),
                          _buildSpecialtyChips(),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Acciones (Sticky bottom) ──────────────────────────────
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: hasChanges
                          ? () {
                              HapticFeedback.lightImpact();
                              setState(
                                  () => _tempFilters = const HomeFilters());
                            }
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd)),
                        minimumSize: const Size(0, 48),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.restart_alt, size: 16),
                          const SizedBox(width: 6),
                          Text('Limpiar', style: AppTypography.label),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context, _tempFilters);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shadowColor: AppColors.primary.withValues(alpha: 0.35),
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd)),
                        ),
                        child: Text(
                          activeCount > 0
                              ? 'Aplicar ($activeCount)'
                              : 'Aplicar filtros',
                          style: AppTypography.label.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  // ── Specialty Chips ───────────────────────────────────────────────────────

  Widget _buildSpecialtyChips() {
    final specialtiesAsync = ref.watch(specialtiesProvider);
    return specialtiesAsync.when(
      data: (specialties) {
        if (specialties.isEmpty) {
          return Text('No hay especialidades disponibles',
              style: AppTypography.bodySm);
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: specialties.map((specialty) {
            final isSelected =
                _tempFilters.specialtyIds.contains(specialty.id);
            return AppChip(
              label: specialty.name,
              selected: isSelected,
              onTap: () {
                final current = List<String>.from(_tempFilters.specialtyIds);
                if (isSelected) {
                  current.remove(specialty.id);
                } else {
                  current.add(specialty.id);
                }
                setState(() =>
                    _tempFilters = _tempFilters.copyWith(specialtyIds: current));
              },
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox(
        height: 32,
        child: Center(
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary)),
      ),
      error: (_, __) => Text('Error al cargar especialidades',
          style: AppTypography.bodySm),
    );
  }

  Widget _buildLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: AppTypography.overline)),
      ],
    );
  }
}
