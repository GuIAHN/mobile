import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/domain/enums/part_type.dart';
import '../../../../../shared/widgets/image_source_selector_sheet.dart';
import '../../../../../shared/widgets/error_view.dart';
import '../../../../../shared/widgets/skeleton_loader.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../vehicles/domain/entities/user_car.dart';
import '../../../../vehicles/presentation/providers/vehicle_providers.dart';
import '../../../../vehicles/presentation/widgets/vehicle_selection_modal.dart';
import '../../../../vehicles/presentation/widgets/_atoms/vehicle_type_illustration.dart';
import '../../../../catalog/domain/entities/category.dart';
import '../../../../chat/presentation/providers/chat_providers.dart';
import '../../providers/home_providers.dart';
import '../form_parts/form_part_type_selector.dart';
import 'category_subcategory_selector_sheet.dart';
import 'request_location_picker_dialog.dart';
import 'request_location_preview.dart';
import 'request_location_selection.dart';

// Parts
part 'spare_part_wizard_step1.dart';
part 'spare_part_wizard_step2.dart';
part 'spare_part_wizard_step3.dart';

class SparePartWizardPage extends ConsumerStatefulWidget {
  final UserCar? initialVehicle;
  final String? initialVariantId;
  final VoidCallback? onSubmitted;

  const SparePartWizardPage({
    super.key,
    this.initialVehicle,
    this.initialVariantId,
    this.onSubmitted,
  });

  static Future<void> show(
    BuildContext context, {
    UserCar? initialVehicle,
    String? initialVariantId,
    VoidCallback? onSubmitted,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SparePartWizardPage(
          initialVehicle: initialVehicle,
          initialVariantId: initialVariantId,
          onSubmitted: onSubmitted,
        ),
      ),
    );
  }

  @override
  ConsumerState<SparePartWizardPage> createState() =>
      _SparePartWizardPageState();
}

class _SparePartWizardPageState extends ConsumerState<SparePartWizardPage> {
  int _currentStep = 1;
  // +1 = avanzando (entra desde la derecha), -1 = retrocediendo.
  int _direction = 1;

  UserCar? _selectedVehicle;
  String? _temporaryModelId;

  @visibleForTesting
  String? get debugTemporaryVariantId => _temporaryModelId;

  Category? _selectedCategory;
  Category? _selectedSubcategory;
  PartType? _selectedPartType;

  final _detailsController = TextEditingController();
  String? _selectedImagePath;
  RequestLocationSelection? _requestLocation;

  @override
  void initState() {
    super.initState();
    _selectedVehicle = widget.initialVehicle;
    _temporaryModelId = widget.initialVariantId;
    _detailsController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() {
      if (_currentStep < 3) {
        _direction = 1;
        _currentStep++;
      }
    });
  }

  Future<void> _prevStep() async {
    if (_currentStep > 1) {
      setState(() {
        _direction = -1;
        _currentStep--;
      });
      return;
    }
    // En el paso 1, salir descarta el vehículo ya elegido: confirmar antes
    // de perderlo silenciosamente.
    if (_selectedVehicle == null) {
      Navigator.pop(context);
      return;
    }
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        title: Text('¿Descartar solicitud?', style: AppTypography.h1),
        content: Text(
          'Perderás el vehículo que ya seleccionaste.',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Text('Cancelar',
                      style: AppTypography.label
                          .copyWith(color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    elevation: 0,
                  ),
                  child: Text('Descartar',
                      style: AppTypography.label.copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (shouldDiscard == true && mounted) {
      Navigator.pop(context);
    }
  }

  void _onVehicleSelected(UserCar car, [String? modelId]) {
    setState(() {
      final isSameTemporaryVehicle =
          car.id.startsWith('temp-') && _selectedVehicle?.id == car.id;
      _selectedVehicle = car;
      _temporaryModelId =
          modelId ?? (isSameTemporaryVehicle ? _temporaryModelId : null);
      // Solo selecciona: avanzar de paso requiere tocar "Continuar",
      // igual que en los pasos 2 y 3.
    });
  }

  Future<void> _openRequestLocationPicker() async {
    final isShared = ref.read(isLocationSharedProvider);
    final current = ref.read(userLocationProvider).valueOrNull;
    final initialSelection = _requestLocation ??
        (isShared && current != null
            ? RequestLocationSelection(
                latitude: current.latitude,
                longitude: current.longitude,
                source: RequestLocationSource.gps,
              )
            : null);

    final result = await RequestLocationPickerDialog.show(
      context,
      initialSelection: initialSelection,
      initialCenter: LatLng(
        initialSelection?.latitude ?? 14.0723,
        initialSelection?.longitude ?? -87.1921,
      ),
    );
    if (result != null && mounted) {
      setState(() => _requestLocation = result);
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
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _submit() async {
    final vehicle = _selectedVehicle;
    final subcat = _selectedSubcategory;
    final partType = _selectedPartType;
    final requestLocation = _requestLocation;

    if (vehicle == null ||
        subcat == null ||
        partType == null ||
        requestLocation == null) {
      return;
    }

    String userCarId = vehicle.id;

    if (vehicle.id.startsWith('temp-')) {
      if (_temporaryModelId == null) {
        context.showSnackBar('Error: Modelo no identificado', isError: true);
        return;
      }
      _showLoadingOverlay();
      final addResult = await ref.read(addCarToGarageUseCaseProvider)(
          variantId: _temporaryModelId!);
      _hideLoadingOverlay();

      if (!mounted) return;
      final registeredCar = addResult.fold((l) {
        context.showSnackBar('Error al registrar vehículo: ${l.message}',
            isError: true);
        return null;
      }, (r) {
        ref.read(authProvider.notifier).addUserCar(r);
        return r;
      });
      if (registeredCar == null) return;
      userCarId = registeredCar.id;
    }

    _showLoadingOverlay();
    await ref.read(searchRequestNotifierProvider.notifier).submitSearch(
          userCarId: userCarId,
          subcategoryId: subcat.id,
          details: _detailsController.text,
          partType: partType,
          fotoUrl: _selectedImagePath,
          lat: requestLocation.latitude,
          lon: requestLocation.longitude,
        );
    _hideLoadingOverlay();

    if (!mounted) return;
    final state = ref.read(searchRequestNotifierProvider);
    if (state.status == SearchRequestStatus.success) {
      _showSuccessDialog();
    } else if (state.status == SearchRequestStatus.error) {
      context.showSnackBar('Error: ${state.errorMessage}', isError: true);
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
            Builder(builder: (context) {
              final reduceMotion = MediaQuery.disableAnimationsOf(context);
              final icon = Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                    color: AppColors.primaryMuted, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 44),
              );
              if (reduceMotion) return icon;
              return TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: icon,
              );
            }),
            const SizedBox(height: 24),
            Text('¡Solicitud enviada!', style: AppTypography.h1),
            const SizedBox(height: 12),
            Text(
              'Hemos enviado tu requerimiento de repuesto a las tiendas afiliadas más cercanas. Te notificaremos en la sección de Chats apenas recibas cotizaciones.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
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
                  Navigator.pop(context); // Close Success
                  Navigator.pop(context); // Close Wizard
                  ref.read(searchRequestNotifierProvider.notifier).reset();
                  ref.invalidate(chatThreadsProvider);
                  widget.onSubmitted?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32)),
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                ),
                child: Text('Entendido',
                    style: AppTypography.label.copyWith(
                      fontSize: 15,
                      color: Colors.white,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Volver',
                    excludeSemantics: true,
                    child: IconButton(
                      onPressed: _prevStep,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20),
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Paso $_currentStep de 3',
                      textAlign: TextAlign.center,
                      style: AppTypography.label.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the icon button
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Semantics(
                label: 'Progreso: paso $_currentStep de 3, '
                    '${_stepLabel(_currentStep)}',
                child: Row(
                  children: [
                    _buildStepIndicator(1),
                    _buildStepIndicatorLine(),
                    _buildStepIndicator(2),
                    _buildStepIndicatorLine(),
                    _buildStepIndicator(3),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            // Content
            Expanded(
              child: Builder(builder: (context) {
                final reduceMotion = MediaQuery.disableAnimationsOf(context);
                return AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    final offset = Tween<Offset>(
                      begin: Offset(_direction * 0.05, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: animation, curve: Curves.easeOut));
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: offset, child: child),
                    );
                  },
                  child: _buildCurrentStep(),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex) {
    final isActive = _currentStep >= stepIndex;
    return Expanded(
      flex: 2,
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.grey200,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildStepIndicatorLine() {
    return const SizedBox(width: 8);
  }

  String _stepLabel(int step) {
    switch (step) {
      case 1:
        return 'Vehículo';
      case 2:
        return 'Repuesto';
      default:
        return 'Detalles';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return _SparePartWizardStep1(
          key: const ValueKey('step1'),
          selectedCar: _selectedVehicle,
          onVehicleSelected: _onVehicleSelected,
          onNext: _nextStep,
        );
      case 2:
        return _SparePartWizardStep2(
          key: const ValueKey('step2'),
          selectedCategory: _selectedCategory,
          selectedSubcategory: _selectedSubcategory,
          selectedPartType: _selectedPartType,
          onCategoryChanged: (cat, subcat) {
            setState(() {
              _selectedCategory = cat;
              _selectedSubcategory = subcat;
            });
          },
          onPartTypeChanged: (pt) {
            setState(() {
              _selectedPartType = pt;
            });
          },
          onNext: _nextStep,
        );
      case 3:
        return SparePartWizardStep3(
          key: const ValueKey('step3'),
          detailsController: _detailsController,
          selectedImagePath: _selectedImagePath,
          isOtroCategory: _selectedSubcategory?.id == kOtherSubcategoryId,
          requestLocation: _requestLocation,
          onLocationTap: _openRequestLocationPicker,
          onImagePicked: (path) => setState(() => _selectedImagePath = path),
          onSubmit: _submit,
        );
      default:
        return const SizedBox();
    }
  }
}
