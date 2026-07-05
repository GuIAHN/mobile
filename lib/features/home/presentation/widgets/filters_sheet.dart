import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../../domain/entities/home_filters.dart';
import '../../domain/entities/sort_option.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';

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
    final mq = MediaQuery.of(context);

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: mq.size.height * 0.88,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                    Text(
                      'Filtros de Búsqueda',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: AppColors.textSecondary,
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.grey100,
                        padding: const EdgeInsets.all(6),
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
                        _buildLabel('ORDENAR POR'),
                        const SizedBox(height: 10),
                        Row(
                          children: SortOption.values.map((option) {
                            final isSelected = _tempFilters.sortBy == option;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _tempFilters = _tempFilters.copyWith(sortBy: option)),
                                child: Container(
                                  margin: EdgeInsets.only(
                                      right: option == SortOption.values.last ? 0 : 8),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Text(
                                    option.label,
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // ── Radio de búsqueda (solo mecánicos/talleres) ──
                        if (_isProviderSearch) ...[
                          _buildLabel('RADIO DE BÚSQUEDA'),
                          const SizedBox(height: 10),
                          Row(
                            children: [5.0, 10.0, 20.0, 30.0, 50.0].map((km) {
                              final isSelected = _tempFilters.radioKm == km;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(
                                      () => _tempFilters = _tempFilters.copyWith(radioKm: km)),
                                  child: Container(
                                    margin: EdgeInsets.only(right: km == 50.0 ? 0 : 6),
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primary : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primary : AppColors.border,
                                      ),
                                    ),
                                    child: Text(
                                      '${km.toInt()} km',
                                      style: GoogleFonts.hankenGrotesk(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? Colors.white : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],


                        // ── Valoración mínima ─────────────────────────────
                        _buildLabel('VALORACIÓN MÍNIMA'),
                        const SizedBox(height: 10),
                        Row(
                          children: [0.0, 3.0, 4.0, 4.5].map((rating) {
                            final isSelected = _tempFilters.minRating == rating;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() =>
                                    _tempFilters = _tempFilters.copyWith(minRating: rating)),
                                child: Container(
                                  margin: EdgeInsets.only(right: rating == 4.5 ? 0 : 8),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primaryMuted : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.border,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: rating == 0.0
                                      ? Text(
                                          'Todas',
                                          style: GoogleFonts.hankenGrotesk(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: isSelected
                                                ? AppColors.primary
                                                : AppColors.textPrimary,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.star_rounded,
                                                size: 13,
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : const Color(0xFFF59E0B)),
                                            const SizedBox(width: 3),
                                            Text(
                                              '$rating+',
                                              style: GoogleFonts.hankenGrotesk(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : AppColors.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // ── Especialidades (solo mecánicos/talleres) ──────
                        if (_isProviderSearch) ...[
                          _buildLabel('ESPECIALIDADES'),
                          const SizedBox(height: 10),
                          _buildSpecialtyChips(),
                          const SizedBox(height: 24),
                        ],

                        // ── Solo abiertos ─────────────────────────────────
                        GestureDetector(
                          onTap: () => setState(() =>
                              _tempFilters =
                                  _tempFilters.copyWith(onlyOpen: !_tempFilters.onlyOpen)),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.grey50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border, width: 0.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check,
                                      size: 16, color: AppColors.success),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Mostrar solo disponibles ahora',
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 48,
                                  height: 26,
                                  padding: const EdgeInsets.all(2),
                                  alignment: _tempFilters.onlyOpen
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  decoration: BoxDecoration(
                                    color: _tempFilters.onlyOpen
                                        ? AppColors.primary
                                        : AppColors.grey300,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
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
                          ? () =>
                              setState(() => _tempFilters = const HomeFilters())
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.restart_alt, size: 16),
                          const SizedBox(width: 6),
                          Text('Limpiar',
                              style: GoogleFonts.hankenGrotesk(
                                  fontSize: 14, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, _tempFilters),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shadowColor: AppColors.primary.withValues(alpha: 0.35),
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'APLICAR FILTROS',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
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
    );
  }

  /// Chips multi-selección de especialidades cargadas del catálogo.
  Widget _buildSpecialtyChips() {
    final specialtiesAsync = ref.watch(specialtiesProvider);
    return specialtiesAsync.when(
      data: (specialties) {
        if (specialties.isEmpty) {
          return Text(
            'No hay especialidades disponibles',
            style: GoogleFonts.hankenGrotesk(
                fontSize: 13, color: AppColors.textSecondary),
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: specialties.map((specialty) {
            final isSelected =
                _tempFilters.specialtyIds.contains(specialty.id);
            return GestureDetector(
              onTap: () {
                final current =
                    List<String>.from(_tempFilters.specialtyIds);
                if (isSelected) {
                  current.remove(specialty.id);
                } else {
                  current.add(specialty.id);
                }
                setState(() =>
                    _tempFilters = _tempFilters.copyWith(specialtyIds: current));
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  specialty.name,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                ),
              ),
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
      error: (_, __) => Text(
        'Error al cargar especialidades',
        style: GoogleFonts.hankenGrotesk(
            fontSize: 13, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.hankenGrotesk(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: AppColors.textSecondary,
      ),
    );
  }
}
