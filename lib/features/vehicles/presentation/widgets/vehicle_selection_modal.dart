import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/brand.dart';
import '../providers/vehicle_providers.dart';

class VehicleSelectionResult {
  final Brand brand;
  final String modelName;
  final int year;
  final String modelId;

  VehicleSelectionResult({
    required this.brand,
    required this.modelName,
    required this.year,
    required this.modelId,
  });
}

class VehicleSelectionModal extends ConsumerStatefulWidget {
  const VehicleSelectionModal({super.key});

  /// Abre el modal y devuelve el resultado de la selección.
  static Future<VehicleSelectionResult?> show(BuildContext context) {
    return showModalBottomSheet<VehicleSelectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VehicleSelectionModal(),
    );
  }

  @override
  ConsumerState<VehicleSelectionModal> createState() => _VehicleSelectionModalState();
}

class _VehicleSelectionModalState extends ConsumerState<VehicleSelectionModal> {
  int _step = 1; // 1: Marca, 2: Modelo, 3: Año
  String _searchQuery = '';

  Brand? _selectedBrand;
  String? _selectedModelName;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Handle drag
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textDisabled,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                if (_step > 1)
                  IconButton(
                    onPressed: _retrocederPaso,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: AppColors.textPrimary,
                  )
                else
                  const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    _tituloPaso(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.hankenGrotesk(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: _placeholderBuscador(),
                hintStyle: GoogleFonts.hankenGrotesk(
                  color: AppColors.textDisabled,
                  fontSize: 15,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildPasoActual(),
            ),
          ),
        ],
      ),
    );
  }

  String _tituloPaso() {
    switch (_step) {
      case 1:
        return 'Selecciona la Marca';
      case 2:
        return 'Modelo de ${_selectedBrand?.name}';
      case 3:
        return 'Año del $_selectedModelName';
      default:
        return '';
    }
  }

  String _placeholderBuscador() {
    switch (_step) {
      case 1:
        return 'Buscar marca...';
      case 2:
        return 'Buscar modelo...';
      case 3:
        return 'Buscar año...';
      default:
        return '';
    }
  }

  void _retrocederPaso() {
    setState(() {
      if (_step == 3) {
        _step = 2;
        _searchQuery = '';
      } else if (_step == 2) {
        _step = 1;
        _selectedBrand = null;
        _searchQuery = '';
      }
    });
  }

  Widget _buildPasoActual() {
    switch (_step) {
      case 1:
        return _buildMarcas();
      case 2:
        return _buildModelos();
      case 3:
        return _buildAnios();
      default:
        return const SizedBox();
    }
  }

  Widget _buildMarcas() {
    final brandsAsync = ref.watch(brandsProvider);

    return brandsAsync.when(
      data: (brands) {
        final filtradas = brands
            .where((b) => b.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        if (filtradas.isEmpty) return _emptyState('No se encontraron marcas');

        return GridView.builder(
          key: const ValueKey('marcas'),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.2,
          ),
          itemCount: filtradas.length,
          itemBuilder: (context, index) {
            final brand = filtradas[index];
            return _CardItem(
              label: brand.name,
              onTap: () {
                setState(() {
                  _selectedBrand = brand;
                  _step = 2;
                  _searchQuery = '';
                });
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildModelos() {
    if (_selectedBrand == null) return const SizedBox();
    final modelsAsync = ref.watch(brandModelsProvider(_selectedBrand!.id));

    return modelsAsync.when(
      data: (models) {
        final distinctNames = models.map((m) => m.name).toSet().toList();
        final filtradas = distinctNames
            .where((m) => m.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        if (filtradas.isEmpty) return _emptyState('No se encontraron modelos');

        return ListView.separated(
          key: const ValueKey('modelos'),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          itemCount: filtradas.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final modelName = filtradas[index];
            return _ListItem(
              label: modelName,
              onTap: () {
                setState(() {
                  _selectedModelName = modelName;
                  _step = 3;
                  _searchQuery = '';
                });
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildAnios() {
    if (_selectedBrand == null || _selectedModelName == null) return const SizedBox();
    final modelsAsync = ref.watch(brandModelsProvider(_selectedBrand!.id));

    return modelsAsync.when(
      data: (models) {
        final availableModels = models.where((m) => m.name == _selectedModelName).toList();
        final availableYears = availableModels.map((m) => m.year).toSet().toList();
        availableYears.sort((a, b) => b.compareTo(a));

        final filtradas = availableYears
            .where((y) => y.toString().contains(_searchQuery))
            .toList();

        if (filtradas.isEmpty) return _emptyState('No se encontraron años');

        return GridView.builder(
          key: const ValueKey('anios'),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.0,
          ),
          itemCount: filtradas.length,
          itemBuilder: (context, index) {
            final year = filtradas[index];
            return _CardItem(
              label: year.toString(),
              onTap: () {
                final modelDef = availableModels.firstWhere((m) => m.year == year);
                Navigator.pop(
                  context,
                  VehicleSelectionResult(
                    brand: _selectedBrand!,
                    modelName: _selectedModelName!,
                    year: year,
                    modelId: modelDef.id,
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(
          message,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CardItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CardItem({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ListItem({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
