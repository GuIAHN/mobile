import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../domain/entities/brand.dart';
import '../../domain/entities/car_model.dart';
import '../providers/vehicle_providers.dart';

class VehicleSelectionResult {
  final Brand brand;
  final String modelId;
  final String modelName;
  final String vehicleType;
  final int year;
  final String motor;

  VehicleSelectionResult({
    required this.brand,
    required this.modelId,
    required this.modelName,
    required this.vehicleType,
    required this.year,
    required this.motor,
  });
}

class VehicleSelectionModal extends ConsumerStatefulWidget {
  final Brand? initialBrand;

  const VehicleSelectionModal({super.key, this.initialBrand});

  /// Abre el modal y devuelve el resultado de la selección.
  static Future<VehicleSelectionResult?> show(BuildContext context,
      {Brand? initialBrand}) {
    return showModalBottomSheet<VehicleSelectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VehicleSelectionModal(initialBrand: initialBrand),
    );
  }

  @override
  ConsumerState<VehicleSelectionModal> createState() =>
      _VehicleSelectionModalState();
}

class _VehicleSelectionModalState extends ConsumerState<VehicleSelectionModal>
    with WidgetsBindingObserver {
  static const int _oldestVehicleYear = 1950;
  int _step = 1;
  String _searchQuery = '';
  String? _yearError;
  late final TextEditingController _yearController;
  late final TextEditingController _motorController;
  late final FocusNode _yearFocusNode;
  late final FocusNode _motorFocusNode;
  late final ScrollController _detailsScrollController;

  Brand? _selectedBrand;
  CarModel? _selectedModel;
  int get _newestVehicleYear => DateTime.now().year + 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _yearController = TextEditingController(text: '${DateTime.now().year}');
    _motorController = TextEditingController();
    _yearFocusNode = FocusNode();
    _motorFocusNode = FocusNode()..addListener(_handleMotorFocus);
    _detailsScrollController = ScrollController();
    if (widget.initialBrand != null) {
      _selectedBrand = widget.initialBrand;
      _step = 2; // Pass directly to model selection
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _yearController.dispose();
    _motorController.dispose();
    _yearFocusNode.dispose();
    _detailsScrollController.dispose();
    _motorFocusNode
      ..removeListener(_handleMotorFocus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _dismissKeyboard,
      child: SafeArea(
        top: false,
        child: Container(
          height: mediaQuery.size.height * 0.85,
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
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20),
                      tooltip: 'Volver',
                      constraints: const BoxConstraints.tightFor(
                        width: 48,
                        height: 48,
                      ),
                      color: AppColors.textPrimary,
                    )
                  else
                    const SizedBox(width: 48),
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
                    tooltip: 'Cerrar selector',
                    constraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Search is useful for textual catalogs; the compact year wheel
            // replaces it in step 3.
            if (_step != 3)
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Content
            Expanded(
              child: AnimatedSwitcher(
                duration: mediaQuery.disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 300),
                child: _buildPasoActual(),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _handleMotorFocus() {
    if (_motorFocusNode.hasFocus) _revealMotorField();
  }

  @override
  void didChangeMetrics() {
    if (_motorFocusNode.hasFocus) _revealMotorField();
  }

  void _revealMotorField() {
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted || !_motorFocusNode.hasFocus) return;
      if (!_detailsScrollController.hasClients) return;
      _detailsScrollController.animateTo(
        _detailsScrollController.position.maxScrollExtent,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _tituloPaso() {
    switch (_step) {
      case 1:
        return 'Selecciona la Marca';
      case 2:
        return 'Modelo de ${_selectedBrand?.name}';
      case 3:
        return 'Completa tu vehículo';
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
        return '';
      default:
        return '';
    }
  }

  void _retrocederPaso() {
    setState(() {
      if (_step == 3) {
        _step = 2;
        _selectedModel = null;
        _yearController.text = '${DateTime.now().year}';
        _motorController.clear();
        _yearError = null;
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
        return _buildVehicleDetails();
      default:
        return const SizedBox();
    }
  }

  Widget _buildMarcas() {
    final brandsAsync = ref.watch(brandsProvider);

    return brandsAsync.when(
      data: (brands) {
        final filtradas = brands
            .where((b) =>
                b.name.toLowerCase().contains(_searchQuery.toLowerCase()))
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
            .where((m) =>
                m.name.toLowerCase().contains(_searchQuery.toLowerCase()))
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
                  _yearController.text = '${DateTime.now().year}';
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

  Widget _buildVehicleDetails() {
    if (_selectedBrand == null || _selectedModel == null) {
      return const SizedBox();
    }
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    final keyboardClearance = keyboardVisible ? (isIos ? 380.0 : 240.0) : 24.0;
    return SingleChildScrollView(
      key: const ValueKey('vehicle-details'),
      controller: _detailsScrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        24,
        4,
        24,
        keyboardClearance,
      ),
      child: Form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _VehicleDepthPreview(
              brand: _selectedBrand!.name,
              brandPhotoUrl: _selectedBrand!.photoUrl,
              model: _selectedModel!.name,
              vehicleType: _selectedModel!.vehicleType,
            ),
            const SizedBox(height: 24),
            Text('AÑO',
                style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('vehicle-year-input'),
              controller: _yearController,
              focusNode: _yearFocusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4)
              ],
              onChanged: (_) => setState(() => _yearError = null),
              onTapOutside: (_) => _dismissKeyboard(),
              onSubmitted: (_) {
                _motorFocusNode.requestFocus();
                _revealMotorField();
              },
              decoration: _inputDecoration(
                hint: 'Ej. ${DateTime.now().year}',
                icon: AppIcons.period,
                errorText: _yearError,
              ),
            ),
            const SizedBox(height: 18),
            Text('MOTOR (OPCIONAL)',
                style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
                key: const ValueKey('vehicle-motor-input'),
                controller: _motorController,
                focusNode: _motorFocusNode,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                maxLength: 100,
                scrollPadding: EdgeInsets.only(
                  bottom: isIos ? 320 : 200,
                ),
                onTap: _revealMotorField,
                onTapOutside: (_) => _dismissKeyboard(),
                onSubmitted: (_) => _dismissKeyboard(),
                decoration: _inputDecoration(
                  hint: 'Ej. 1.8L, 2.0 Turbo',
                  icon: AppIcons.engine,
                  helperText:
                      'Escríbelo como aparece en el vehículo o documento.',
                ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                key: const ValueKey('confirm-vehicle-details'),
                onPressed: _completeSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32)),
                ),
                child: Text('CONFIRMAR VEHÍCULO',
                    style: GoogleFonts.hankenGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
      {required String hint,
      required IconData icon,
      String? errorText,
      String? helperText}) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      helperText: helperText,
      counterText: '',
      prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
    );
  }

  void _completeSelection() {
    final year = int.tryParse(_yearController.text.trim());
    if (year == null ||
        year < _oldestVehicleYear ||
        year > _newestVehicleYear) {
      setState(() => _yearError =
          'Ingresa un año entre $_oldestVehicleYear y $_newestVehicleYear.');
      return;
    }
    Navigator.pop(
      context,
      VehicleSelectionResult(
        brand: _selectedBrand!,
        modelId: _selectedModel!.id,
        modelName: _selectedModel!.name,
        vehicleType: _selectedModel!.vehicleType,
        year: year,
        motor: _motorController.text.trim(),
      ),
    );
  }

/* Legacy variant picker removed with the backend vehicle-variant catalog.
        return Padding(
          key: const ValueKey('anios'),
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            children: [
              Text(
                'Desliza para elegir cualquier año',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Semantics(
                  label: 'Selector de año',
                  value: '${_selectedYear ?? DateTime.now().year}',
                  child: ListWheelScrollView.useDelegate(
                    key: const ValueKey('vehicle-year-wheel'),
                    controller: _yearController,
                    itemExtent: 52,
                    diameterRatio: 1.7,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) =>
                        setState(() => _selectedYear = years[index]),
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: years.length,
                      builder: (context, index) {
                        final year = years[index];
                        final selected = year == _selectedYear;
                        return Center(
                          child: Text(
                            '$year',
                            key: ValueKey('vehicle-year-$year'),
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: selected ? 28 : 20,
                              fontWeight:
                                  selected ? FontWeight.w800 : FontWeight.w500,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              if (_yearError != null) ...[
                Text(
                  _yearError!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  key: const ValueKey('confirm-vehicle-year'),
                  onPressed:
                      _isResolvingYear ? null : () => _confirmYear(variants),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.disabledBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: _isResolvingYear
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'CONTINUAR',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => _loadingState('Cargando años disponibles'),
      error: (_, __) => _variantsErrorState(),
    );
  }

  Future<void> _confirmYear(List<VehicleVariant> variants) async {
    final year = _selectedYear ?? DateTime.now().year;
    final variantsForYear =
        variants.where((variant) => variant.year == year).toList();
    if (variantsForYear.isNotEmpty) {
      setState(() {
        _selectedYear = year;
        _step = 4;
        _searchQuery = '';
      });
      return;
    }

    setState(() {
      _isResolvingYear = true;
      _yearError = null;
    });
    try {
      final variant = await ref.read(
        ensureModelYearVariantProvider(
            (modelId: _selectedModel!.id, year: year)).future,
      );
      if (mounted) _completeSelection(variant);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isResolvingYear = false;
        _yearError = 'No pudimos registrar este año. Inténtalo de nuevo.';
      });
    }
  }

  Widget _buildVariantesDelAnio() {
    if (_selectedBrand == null ||
        _selectedModel == null ||
        _selectedYear == null) {
      return const SizedBox();
    }

    final variantsAsync = ref.watch(modelVariantsProvider(_selectedModel!.id));

    return variantsAsync.when(
      data: (variants) {
        final query = _searchQuery.trim().toLowerCase();
        final variantsForYear = variants
            .where((variant) =>
                variant.year == _selectedYear &&
                variant.motor.toLowerCase().contains(query))
            .toList()
          ..sort((a, b) => a.motor.compareTo(b.motor));

        if (variantsForYear.isEmpty) {
          return _emptyState(
            query.isEmpty
                ? 'No hay motores disponibles para este año'
                : 'No se encontraron motores',
          );
        }

        return ListView.separated(
          key: const ValueKey('variantes-del-anio'),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          itemCount: variantsForYear.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final variant = variantsForYear[index];
            final motor = variant.motor.trim();

            return _ListItem(
              key: ValueKey('vehicle-variant-${variant.id}'),
              label: motor.isEmpty ? 'Versión estándar' : motor,
              subtitle: 'Año ${variant.year}',
              onTap: () => _completeSelection(variant),
            );
          },
        );
      },
      loading: () => _loadingState('Cargando motores disponibles'),
      error: (_, __) => _variantsErrorState(),
    );
  }

  void _completeSelection(VehicleVariant variant) {
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
  }
*/

  Widget _emptyState(String message) {
    return Semantics(
      label: message,
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleDepthPreview extends StatelessWidget {
  final String brand;
  final String? brandPhotoUrl;
  final String model;
  final String vehicleType;

  const _VehicleDepthPreview({
    required this.brand,
    this.brandPhotoUrl,
    required this.model,
    required this.vehicleType,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'Vehículo seleccionado: $brand $model',
      child: ExcludeSemantics(
        child: SizedBox(
          height: 132,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                bottom: 12,
                child: Container(
                  width: 190,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.16),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, reduceMotion ? 0 : 0.0015)
                  ..rotateX(reduceMotion ? 0 : -0.10)
                  ..rotateY(reduceMotion ? 0 : -0.08),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      SizedBox.square(
                        dimension: 72,
                        child: _BrandLogo(
                          brand: brand,
                          photoUrl: brandPhotoUrl,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(brand.toUpperCase(),
                                style: GoogleFonts.hankenGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                    color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(model,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.hankenGrotesk(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  final String brand;
  final String? photoUrl;

  const _BrandLogo({required this.brand, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim();
    final fallback = Center(
      child: Text(
        brand.isEmpty ? '?' : brand.characters.first.toUpperCase(),
        style: GoogleFonts.hankenGrotesk(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
    if (url == null || url.isEmpty) return fallback;
    if (url.toLowerCase().endsWith('.svg')) {
      return SvgPicture.network(
        url,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => fallback,
      );
    }
    return Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => fallback,
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
            child: Icon(Icons.directions_car,
                color: AppColors.textDisabled, size: 32),
          ),
        );
      } else {
        logoWidget = Image.network(
          brand.photoUrl!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.directions_car,
              color: AppColors.textDisabled,
              size: 32),
        );
      }
    } else {
      logoWidget = const Icon(Icons.directions_car,
          color: AppColors.textDisabled, size: 32);
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
  final VoidCallback onTap;

  const _ListItem({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
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
            children: [
              Expanded(
                child: Column(
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
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
