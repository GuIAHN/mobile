import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/image_source_selector_sheet.dart';
import '../../../../core/domain/enums/user_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../catalog/domain/entities/category.dart';
import '../../../vehicles/presentation/providers/vehicle_providers.dart';
import '../../../../core/utils/async_error_listener.dart';
import '../providers/home_providers.dart';
import '../../../../core/domain/enums/part_type.dart';
import '../../../../core/utils/extensions.dart';
import '../../../vehicles/presentation/widgets/garage_vehicle_selector_sheet.dart';
import '../../../../core/services/location_service.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import 'form_parts/form_part_type_selector.dart';
import 'spare_part_wizard/category_subcategory_selector_sheet.dart';

class RequestSparePartForm extends ConsumerStatefulWidget {
  final VoidCallback? onSubmitted;

  const RequestSparePartForm({
    super.key,
    this.onSubmitted,
  });

  @override
  ConsumerState<RequestSparePartForm> createState() =>
      _RequestSparePartFormState();
}

class _RequestSparePartFormState extends ConsumerState<RequestSparePartForm> {
  final _detailsController = TextEditingController();
  int _currentStep = 0;
  int _previousStep = 0;

  Category? _selectedCategory;
  Category? _selectedSubcategory;
  PartType? _selectedPartType;

  String? _selectedImagePath;
  final ImagePicker _picker = ImagePicker();

  bool get _isOtroCategory =>
      _selectedSubcategory?.id == 'other_subcategory_id';

  String? _categorySelectorValue() {
    final category = _selectedCategory;
    final subcategory = _selectedSubcategory;
    if (category == null || subcategory == null) return null;
    if (category.id == 'other_category_id') {
      return 'Otro (categoría no listada)';
    }
    if (subcategory.id == 'other_subcategory_id') {
      return '${category.name}  ▸  Otro';
    }
    return '${category.name}  ▸  ${subcategory.name}';
  }

  @override
  void initState() {
    super.initState();
    _detailsController.addListener(_handleDetailsChange);
  }


  void _nextStep() {
    setState(() {
      if (_currentStep < 2) {
        _previousStep = _currentStep;
        _currentStep++;
      }
    });
  }

  void _prevStep() {
    setState(() {
      if (_currentStep > 0) {
        _previousStep = _currentStep;
        _currentStep--;
      }
    });
  }

  void _handleDetailsChange() {
    // Recalcula la validez del formulario mientras el usuario escribe,
    // relevante cuando la categoría "Otro" exige detalles obligatorios.
    setState(() {});
  }

  @override
  void dispose() {
    _detailsController.removeListener(_handleDetailsChange);
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar(
          'Error al seleccionar imagen: $e',
          isError: true,
        );
      }
    }
  }

  void _mostrarSelectorDeImagen() async {
    final source = await ImageSourceSelectorSheet.show(context);
    if (source != null) {
      _pickImage(source);
    }
  }

  void _showLoadingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  void _hideLoadingOverlay() {
    Navigator.pop(context);
  }

  void _abrirSelectorVehiculo() async {
    final result = await GarageVehicleSelectorSheet.show(
      context,
      selectedCar: ref.read(searchVehicleProvider),
    );
    if (result != null) {
      ref.read(searchVehicleVariantIdProvider.notifier).state = result.variantId;
      ref.read(searchVehicleProvider.notifier).state = result.car;
    }
  }

  void _onSubmit() async {
    final globalVehicle = ref.read(searchVehicleProvider);
    final selectedSubcategory = _selectedSubcategory;
    final selectedPartType = _selectedPartType;
    if (globalVehicle == null ||
        selectedSubcategory == null ||
        selectedPartType == null) {
      return;
    }

    String userCarId = globalVehicle.id;

    // If it's a temporary vehicle (manual entry), register it in the garage first
    if (globalVehicle.id.startsWith('temp-')) {
      final variantId = ref.read(searchVehicleVariantIdProvider);
      if (variantId == null) {
        context.showSnackBar(
          'Error: No se pudo identificar la variante del vehículo',
          isError: true,
        );
        return;
      }

      _showLoadingOverlay();
      final addCarResult = await ref.read(addCarToGarageUseCaseProvider)(
        variantId: variantId,
      );
      _hideLoadingOverlay();

      if (!mounted) return;
      final registeredCar = addCarResult.fold(
        (failure) {
          context.showSnackBar(
            'Error al registrar vehículo: ${failure.message}',
            isError: true,
          );
          return null;
        },
        (car) {
          ref.read(searchVehicleProvider.notifier).state = car;
          ref.read(searchVehicleVariantIdProvider.notifier).state = null;
          // Maintain the garage cache in sync
          ref.read(authProvider.notifier).addUserCar(car);
          return car;
        },
      );

      if (registeredCar == null) return;
      userCarId = registeredCar.id;
    }

    double? lat;
    double? lon;
    if (ref.read(isLocationSharedProvider)) {
      final location = ref.read(userLocationProvider).valueOrNull;
      if (location != null) {
        lat = location.latitude;
        lon = location.longitude;
      }
    }

    _showLoadingOverlay();
    await ref.read(searchRequestNotifierProvider.notifier).submitSearch(
          userCarId: userCarId,
          subcategoryId: selectedSubcategory.id,
          details: _detailsController.text,
          partType: selectedPartType,
          fotoUrl: _selectedImagePath,
          lat: lat,
          lon: lon,
        );
    _hideLoadingOverlay();


    if (!mounted) return;
    final searchState = ref.read(searchRequestNotifierProvider);
    if (searchState.status == SearchRequestStatus.success) {
      _showSuccessDialog();
    } else if (searchState.status == SearchRequestStatus.error) {
      context.showSnackBar(
        'Error al enviar solicitud: ${searchState.errorMessage ?? "Error desconocido"}',
        isError: true,
      );
    }
  }

  void _showSuccessDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.primaryMuted,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 44,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '¡Solicitud Enviada!',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Hemos enviado tu requerimiento de repuesto a las tiendas afiliadas más cercanas. Te notificaremos en la sección de Chats apenas recibas cotizaciones.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Cierra bottom sheet
                  // Limpia el formulario
                  _detailsController.clear();
                  setState(() {
                    _selectedCategory = null;
                    _selectedSubcategory = null;
                    _selectedPartType = null;
                    _selectedImagePath = null;
                  });
                  ref.read(searchVehicleProvider.notifier).state = null;
                  ref.read(searchVehicleVariantIdProvider.notifier).state = null;
                  ref.read(searchRequestNotifierProvider.notifier).reset();
                  ref.invalidate(chatThreadsProvider);
                  widget.onSubmitted?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                ),
                child: Text(
                  'ENTENDIDO',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isConsumer = user == null || user.role == UserRole.consumer;

    if (user != null && !user.role.canRequestSpareParts) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.storefront_rounded,
                size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Función no disponible',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Las cuentas de tipo Tienda no pueden solicitar repuestos, únicamente cotizar y responder a las solicitudes de clientes.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    ref.listenAsyncError(userCarsProvider, context);
    final userCarsAsync = ref.watch(userCarsProvider);
    final globalVehicle = ref.watch(searchVehicleProvider);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // Ultra-modern roundness
        border: Border.all(color: AppColors.grey200.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04), // Tinted soft shadow
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24), // More breathing room
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Builder(
            builder: (context) {
              final (icon, iconColor, bgColor, borderColor, title, subtitle) = switch (_currentStep) {
                0 => (
                    Icons.settings_rounded, // Tuerca (Nut)
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.primary.withValues(alpha: 0.25),
                    'Cotiza tu Repuesto',
                    '¿Para qué vehículo es?',
                  ),
                1 => (
                    Icons.build_circle_rounded, // Ensamblando (Building)
                    AppColors.secondary,
                    AppColors.secondary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.25),
                    'Encuentra la Pieza',
                    'Selecciona la categoría',
                  ),
                _ => (
                    Icons.directions_car_rounded, // Carro Armado (Car)
                    AppColors.tertiary,
                    AppColors.tertiary.withValues(alpha: 0.1),
                    AppColors.tertiary.withValues(alpha: 0.25),
                    'Detalles de la Solicitud',
                    'Envía a las tiendas',
                  ),
              };

              return Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim,
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: Icon(
                        icon,
                        key: ValueKey(icon.codePoint),
                        color: iconColor,
                        size: 24, // un poquito mas grande
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      layoutBuilder: (currentChild, previousChildren) => Stack(
                        alignment: Alignment.centerLeft,
                        children: <Widget>[
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      ),
                      child: Column(
                        key: ValueKey(_currentStep),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: iconColor, // <- USAMOS EL COLOR DEL ICONO, CERO NEGRO
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
          ),
          const SizedBox(height: 20),
          _AnimatedStepIndicator(currentStep: _currentStep),
          const SizedBox(height: 24),

          // Wizard content
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.topCenter,
                  children: <Widget>[
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              transitionBuilder: (child, animation) {
                final key = child.key as ValueKey<String>?;
                final step = int.tryParse(key?.value.replaceAll('step', '') ?? '0') ?? 0;
                final isForward = _currentStep >= _previousStep;
                
                double dx = 0;
                if (step == _currentStep) {
                  dx = isForward ? 1.0 : -1.0;
                } else {
                  dx = step < _currentStep ? -1.0 : 1.0;
                }
                
                return SlideTransition(
                  position: Tween<Offset>(begin: Offset(dx, 0.0), end: Offset.zero)
                      .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: _currentStep == 0
                  ? _buildStep1(isConsumer, globalVehicle, userCarsAsync)
                  : _currentStep == 1
                      ? _buildStep2()
                      : _buildStep3(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(bool isConsumer, dynamic globalVehicle, AsyncValue<List<dynamic>> userCarsAsync) {
    final hasVehicle = globalVehicle != null;
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('VEHÍCULO PARA LA SOLICITUD *'),
        const SizedBox(height: 6),
        if (isConsumer) ...[
          userCarsAsync.when(
            data: (garageCars) {
              final String valorMostrado;
              if (globalVehicle != null) {
                if (globalVehicle.id.startsWith('temp-')) {
                  valorMostrado = 'Otro: ${globalVehicle.brand} ${globalVehicle.model} (${globalVehicle.year})';
                } else {
                  valorMostrado = '${globalVehicle.brand} ${globalVehicle.model} (${globalVehicle.year})';
                }
              } else {
                valorMostrado = 'Selecciona de tu garaje u otro';
              }

              return _SelectorField(
                value: globalVehicle != null ? valorMostrado : null,
                placeholder: 'Selecciona un vehículo de tu garaje',
                onTap: _abrirSelectorVehiculo,
              );
            },
            loading: () => _buildLoadingField('Cargando tus vehículos...'),
            error: (_, __) => _SelectorField(
              value: globalVehicle != null
                  ? 'Otro: ${globalVehicle.brand} ${globalVehicle.model}'
                  : null,
              placeholder: 'Ingresa vehículo manual',
              onTap: _abrirSelectorVehiculo,
            ),
          ),
        ] else ...[
          _SelectorField(
            value: globalVehicle != null
                ? '${globalVehicle.brand} ${globalVehicle.model} (${globalVehicle.year})'
                : null,
            placeholder: 'Selecciona marca, modelo y año',
            onTap: _abrirSelectorVehiculo,
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: hasVehicle ? _nextStep : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.grey200,
              disabledForegroundColor: AppColors.textDisabled,
              shape: const StadiumBorder(),
              elevation: hasVehicle ? 4 : 0,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'SIGUIENTE',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    final hasCategory = _selectedCategory != null && _selectedSubcategory != null;
    final hasPartType = _selectedPartType != null;
    final canProceed = hasCategory && hasPartType;

    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('CATEGORÍA DE REPUESTO *'),
        const SizedBox(height: 6),
        _SelectorField(
          value: _categorySelectorValue(),
          placeholder: 'Selecciona categoría y subcategoría',
          onTap: () async {
            final result = await CategorySubcategorySelectorSheet.show(
              context,
              initialCategory: _selectedCategory,
              initialSubcategory: _selectedSubcategory,
            );
            if (result != null) {
              setState(() {
                _selectedCategory = result.category;
                _selectedSubcategory = result.subcategory;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        _buildLabel('TIPO DE REPUESTO *'),
        const SizedBox(height: 8),
        FormPartTypeSelector(
          selectedPartType: _selectedPartType,
          onPartTypeSelected: (type) {
            setState(() {
              _selectedPartType = type;
            });
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _prevStep,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              label: Text(
                'ATRÁS',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: canProceed ? _nextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.grey200,
                  disabledForegroundColor: AppColors.textDisabled,
                  shape: const StadiumBorder(),
                  elevation: canProceed ? 4 : 0,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SIGUIENTE',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3() {
    final needsDetails = _isOtroCategory;
    final hasRequiredDetails = !needsDetails || _detailsController.text.trim().isNotEmpty;

    return Column(
      key: const ValueKey('step3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(
          needsDetails
              ? 'DETALLES ADICIONALES *'
              : 'DETALLES ADICIONALES (OPCIONAL)',
        ),
        if (needsDetails) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 13, color: AppColors.tertiary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Cuéntanos qué repuesto necesitas, ya que no coincide con ninguna categoría del catálogo.',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tertiary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 6),
        _buildTextField(
          controller: _detailsController,
          hint: needsDetails
              ? 'Ej. Kit de embrague completo para motor 2.0L turbo...'
              : 'Ej. Alternador para motor 1.8L, lado derecho, marca Denso...',
          maxLines: 2,
          highlighted: needsDetails,
        ),
        const SizedBox(height: 16),
        _buildLabel('FOTOGRAFÍA DE REFERENCIA (OPCIONAL)'),
        const SizedBox(height: 6),
        _selectedImagePath != null
            ? Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: kIsWeb
                            ? Image.network(
                                _selectedImagePath!,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(_selectedImagePath!),
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImagePath = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : GestureDetector(
                onTap: _mostrarSelectorDeImagen,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.grey300,
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_photo_alternate_outlined,
                          color: AppColors.primary,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Toca para adjuntar foto',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _prevStep,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              label: Text(
                'ATRÁS',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: hasRequiredDetails ? _onSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.grey200,
                  disabledForegroundColor: AppColors.textDisabled,
                  shape: const StadiumBorder(),
                  elevation: hasRequiredDetails ? 4 : 0,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ENVIAR',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.send_rounded, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.hankenGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildLoadingField(String message) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grey300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Text(
            message,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    int maxLines = 1,
    bool highlighted = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.border,
          width: highlighted ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (icon != null)
            Padding(
              padding: EdgeInsets.only(top: maxLines > 1 ? 14 : 0, right: 12),
              child: Icon(icon, color: AppColors.textSecondary, size: 20),
            ),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14.5,
                fontWeight: controller.text.isNotEmpty
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                isCollapsed: true,
                hintText: hint,
                hintStyle: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textDisabled,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _SelectorField extends StatelessWidget {
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  const _SelectorField({
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    final isLongText = hasValue && (value!.contains('▸') || value!.length > 28);
    return Semantics(
      button: true,
      label: value ?? placeholder,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            constraints: const BoxConstraints(minHeight: 44),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasValue ? AppColors.primary : AppColors.border,
                width: hasValue ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  value != null && value!.contains('▸') 
                      ? Icons.category_outlined 
                      : Icons.directions_car_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value ?? placeholder,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: isLongText ? 14 : 16,
                      fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
                      color: hasValue
                          ? AppColors.textPrimary
                          : AppColors.textDisabled,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: hasValue ? AppColors.primary : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Animaciones ────────────────────────────────────────────────────────────

class _AnimatedStepIndicator extends StatelessWidget {
  final int currentStep;

  const _AnimatedStepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepBubble(0, 'Vehículo'),
        _buildConnector(0),
        _buildStepBubble(1, 'Repuesto'),
        _buildConnector(1),
        _buildStepBubble(2, 'Detalles'),
      ],
    );
  }

  Widget _buildStepBubble(int stepIndex, String label) {
    final isCompleted = currentStep > stepIndex;
    final isActive = currentStep == stepIndex;

    Color bgColor = AppColors.grey100;
    Color iconColor = AppColors.textDisabled;
    Color borderColor = AppColors.grey200;

    if (isActive) {
      bgColor = AppColors.primary;
      iconColor = Colors.white;
      borderColor = AppColors.primaryLight;
    } else if (isCompleted) {
      bgColor = AppColors.primaryMuted;
      iconColor = AppColors.primary;
      borderColor = AppColors.primaryMuted;
    }

    return Column(
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          tween: Tween(begin: 0.8, end: isActive ? 1.15 : 1.0),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive ? borderColor.withValues(alpha: 0.5) : borderColor,
                    width: isActive ? 4 : 1,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                    child: isCompleted
                        ? Icon(
                            Icons.check_rounded,
                            key: ValueKey('check_$stepIndex'),
                            color: iconColor,
                            size: 18,
                          )
                        : Text(
                            '${stepIndex + 1}',
                            key: ValueKey('num_$stepIndex'),
                            style: GoogleFonts.hankenGrotesk(
                              color: iconColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 11.5,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: isActive ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(int fromStep) {
    final isCompleted = currentStep > fromStep;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4).copyWith(bottom: 24),
        height: 3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Stack(
            children: [
              Container(color: AppColors.grey200),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                tween: Tween(begin: 0.0, end: isCompleted ? 1.0 : 0.0),
                builder: (context, value, child) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: value,
                    child: Container(color: AppColors.primaryLight),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerSkeleton extends StatefulWidget {
  const _ShimmerSkeleton();

  @override
  State<_ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<_ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                AppColors.grey100,
                Colors.white,
                AppColors.grey100,
              ],
              stops: const [0.1, 0.5, 0.9],
              begin: Alignment(-1.0 + (_controller.value * 2.0), -0.3),
              end: Alignment(1.0 + (_controller.value * 2.0), 0.3),
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Column(
        children: List.generate(5, (i) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Container(
                  width: i.isEven ? 140 : 100,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
