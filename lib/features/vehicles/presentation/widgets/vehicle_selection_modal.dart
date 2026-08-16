import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/brand.dart';
import '../../domain/entities/car_model.dart';
import '../providers/vehicle_providers.dart';

class VehicleSelectionResult {
  final Brand brand;
  final String modelName;
  final int year;
  final String variantId;
  final String motor;

  @Deprecated('Use variantId instead')
  String get modelId => variantId;

  VehicleSelectionResult({
    required this.brand,
    required this.modelName,
    required this.year,
    required this.variantId,
    required this.motor,
  });
}

class VehicleSelectionModal extends ConsumerStatefulWidget {
  final Brand? initialBrand;

  const VehicleSelectionModal({super.key, this.initialBrand});

  /// Abre el modal y devuelve el resultado de la selección.
  static Future<VehicleSelectionResult?> show(BuildContext context, {Brand? initialBrand}) {
    return showModalBottomSheet<VehicleSelectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VehicleSelectionModal(initialBrand: initialBrand),
    );
  }

  @override
  ConsumerState<VehicleSelectionModal> createState() => _VehicleSelectionModalState();
}

class _VehicleSelectionModalState extends ConsumerState<VehicleSelectionModal> {
  int _step = 1; // 1: Marca, 2: Modelo, 3: Año / Variante
  String _searchQuery = '';

  Brand? _selectedBrand;
  CarModel? _selectedModel;

  @override
  void initState() {
    super.initState();
    if (widget.initialBrand != null) {
      _selectedBrand = widget.initialBrand;
      _step = 2; // Pass directly to model selection
    }
  }

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
        return 'Año / Versión de ${_selectedModel?.name}';
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
        return 'Buscar año o motor...';
      default:
        return '';
    }
  }

  void _retrocederPaso() {
    setState(() {
      if (_step == 3) {
        _step = 2;
        _selectedModel = null;
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
        return _buildVariantes();
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
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: filtradas.length,
          itemBuilder: (context, index) {
            final brand = filtradas[index];
            return _BrandCard(
              brand: brand,
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
        final filtradas = models
            .where((m) => m.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        if (filtradas.isEmpty) return _emptyState('No se encontraron modelos');

        return ListView.separated(
          key: const ValueKey('modelos'),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          itemCount: filtradas.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final model = filtradas[index];
            return _ListItem(
              label: model.name,
              onTap: () {
                setState(() {
                  _selectedModel = model;
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

  Widget _buildVariantes() {
    if (_selectedBrand == null || _selectedModel == null) return const SizedBox();
    final variantsAsync = ref.watch(modelVariantsProvider(_selectedModel!.id));

    return variantsAsync.when(
      data: (variants) {
        final filtradas = variants
            .where((v) =>
                v.year.toString().contains(_searchQuery) ||
                v.motor.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
        filtradas.sort((a, b) => b.year.compareTo(a.year));

        if (filtradas.isEmpty) return _emptyState('No se encontraron años/versiones');

        return ListView.separated(
          key: const ValueKey('variantes'),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          itemCount: filtradas.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final variant = filtradas[index];
            final title = 'Año ${variant.year}';
            final subtitle = variant.motor.isNotEmpty ? variant.motor : null;

            return _ListItem(
              label: title,
              subtitle: subtitle,
              onTap: () {
                Navigator.pop(
                  context,
                  VehicleSelectionResult(
                    brand: _selectedBrand!,
                    modelName: _selectedModel!.name,
                    year: variant.year,
                    variantId: variant.id,
                    motor: variant.motor,
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

class _BrandCard extends StatelessWidget {
  final Brand brand;
  final VoidCallback onTap;

  const _BrandCard({required this.brand, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Widget logoWidget;
    if (brand.photoUrl != null && brand.photoUrl!.isNotEmpty) {
      if (brand.photoUrl!.toLowerCase().endsWith('.svg')) {
        logoWidget = SvgPicture.network(
          brand.photoUrl!,
          fit: BoxFit.contain,
          placeholderBuilder: (context) => const Center(
            child: Icon(Icons.directions_car, color: AppColors.textDisabled, size: 32),
          ),
        );
      } else {
        logoWidget = Image.network(
          brand.photoUrl!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.directions_car, color: AppColors.textDisabled, size: 32),
        );
      }
    } else {
      logoWidget = const Icon(Icons.directions_car, color: AppColors.textDisabled, size: 32);
    }

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: logoWidget,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
              child: Text(
                brand.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _ListItem({
    required this.label,
    this.subtitle,
    required this.onTap,
  });

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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
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
