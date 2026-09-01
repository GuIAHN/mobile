import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/router/route_names.dart';
import '../../../../../core/domain/enums/part_type.dart';
import '../../../../../shared/widgets/image_source_selector_sheet.dart';
import '../../../../../shared/widgets/error_view.dart';
import '../../../../../shared/widgets/skeleton_loader.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../core/domain/entities/user_car.dart';
import '../../../../vehicles/presentation/providers/vehicle_providers.dart';
import '../../../../vehicles/presentation/widgets/vehicle_selection_modal.dart';
import '../../../../vehicles/presentation/widgets/_atoms/vehicle_type_illustration.dart';
import '../../../../catalog/domain/entities/category.dart';
import '../../../../chat/presentation/providers/chat_providers.dart';
import '../../../../reviews/presentation/providers/reviews_providers.dart';
import '../../providers/home_providers.dart';
import '../form_parts/form_part_type_selector.dart';
import 'category_subcategory_selector_sheet.dart';
import 'request_location_seed.dart';
import '../../../../../shared/location/domain/entities/request_location_selection.dart';
import '../../../../../shared/location/presentation/widgets/request_location_picker_dialog.dart';
import '../../../../../shared/location/presentation/widgets/request_location_preview.dart';

// Parts
part 'spare_part_wizard_step1.dart';
part 'spare_part_wizard_step2.dart';
part 'spare_part_wizard_step3.dart';
part 'spare_part_wizard_chrome.dart';
part 'spare_part_wizard_summary.dart';
part 'vehicle_option_card.dart';
part 'cbk_recommendation_dialog.dart';

class SparePartWizardPage extends ConsumerStatefulWidget {
  final UserCar? initialVehicle;
  final String? initialModelId;
  final VoidCallback? onSubmitted;

  const SparePartWizardPage({
    super.key,
    this.initialVehicle,
    this.initialModelId,
    this.onSubmitted,
  });

  static Future<void> show(
    BuildContext context, {
    UserCar? initialVehicle,
    String? initialModelId,
    VoidCallback? onSubmitted,
  }) async {
    final container = ProviderScope.containerOf(context);
    final pendingState = container.read(pendingReviewsProvider);
    var loadingVisible = false;

    if (!pendingState.hasValue) {
      loadingVisible = true;
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    var pendingCount = 0;
    try {
      final cachedItems = pendingState.valueOrNull;
      if (cachedItems != null) {
        pendingCount = cachedItems.length;
      } else {
        final pendingItems =
            await container.read(pendingReviewsProvider.future);
        pendingCount = pendingItems.length;
      }
    } catch (_) {
      // Una falla al consultar recordatorios no debe bloquear una solicitud.
      // El backend repite esta validación antes de crearla.
    } finally {
      if (loadingVisible && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (!context.mounted) return;
    if (pendingCount > 1) {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _PendingReviewsGateSheet(count: pendingCount),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SparePartWizardPage(
          initialVehicle: initialVehicle,
          initialModelId: initialModelId,
          onSubmitted: onSubmitted,
        ),
      ),
    );
  }

  @override
  ConsumerState<SparePartWizardPage> createState() =>
      _SparePartWizardPageState();
}

class _PendingReviewsGateSheet extends StatelessWidget {
  final int count;

  const _PendingReviewsGateSheet({required this.count});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 24),
            const AppLineIcon(
              AppIcons.rating,
              size: AppIconSize.feature,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Tienes valoraciones pendientes',
              textAlign: TextAlign.center,
              style: AppTypography.h2,
            ),
            const SizedBox(height: 10),
            Text(
              'Antes de pedir otro repuesto, ayúdanos a cerrar tus compras anteriores. Tienes $count reseñas pendientes y completarlas solo te tomará un momento.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push(RouteNames.pendingReviews);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                child: Text(
                  'IR A RESEÑAS PENDIENTES',
                  style: AppTypography.label.copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'AHORA NO',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SparePartWizardPageState extends ConsumerState<SparePartWizardPage> {
  static const _cbkPreference =
      'Pastillas CBK preferiblemente para mi compra, por favor';

  int _currentStep = 1;
  late final PageController _pageController;
  bool _isSubmitting = false;
  String? _submitError;
  bool _isDirty = false;

  UserCar? _selectedVehicle;
  String? _temporaryModelId;

  @visibleForTesting
  String? get debugTemporaryModelId => _temporaryModelId;

  @visibleForTesting
  double? get debugWizardPage =>
      _pageController.hasClients ? _pageController.page : null;

  Category? _selectedCategory;
  Category? _selectedSubcategory;
  PartType? _selectedPartType;

  final _detailsController = TextEditingController();
  String? _selectedImagePath;
  RequestLocationSelection? _requestLocation;
  bool _isLocatingRequest = false;
  bool _requestedCurrentLocation = false;
  String? _requestLocationError;
  String? _cbkPromptedSubcategoryId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _selectedVehicle = widget.initialVehicle;
    _temporaryModelId = widget.initialModelId;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _goToStep(int nextStep) async {
    if (nextStep < 1 || nextStep > 3 || nextStep == _currentStep) return;
    FocusManager.instance.primaryFocus?.unfocus();
    // A full-page slide keeps both dense form steps visible at once and can
    // look frozen on iOS. Swap the page immediately; the header and progress
    // indicator provide the lightweight continuity cue.
    _pageController.jumpToPage(nextStep - 1);
    setState(() {
      _currentStep = nextStep;
      _submitError = null;
    });
    if (nextStep == 3) {
      await _showCbkRecommendationIfNeeded();
      if (!mounted) return;
      await _loadCurrentRequestLocation();
    }
  }

  Future<void> _showCbkRecommendationIfNeeded() async {
    final subcategory = _selectedSubcategory;
    if (subcategory == null ||
        !_isBrakePads(subcategory.name) ||
        _cbkPromptedSubcategoryId == subcategory.id) {
      return;
    }

    _cbkPromptedSubcategoryId = subcategory.id;
    final acceptsRecommendation = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) => const _CbkRecommendationSheet(),
    );
    if (!mounted || acceptsRecommendation != true) return;

    final currentDetails = _detailsController.text.trim();
    if (currentDetails.toLowerCase().contains(_cbkPreference.toLowerCase())) {
      return;
    }

    _detailsController.text = currentDetails.isEmpty
        ? _cbkPreference
        : '$currentDetails\n$_cbkPreference';
    _detailsController.selection = TextSelection.collapsed(
      offset: _detailsController.text.length,
    );
    setState(() => _isDirty = true);
  }

  bool _isBrakePads(String name) {
    final normalized =
        name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9áéíóúüñ]+'), ' ').trim();
    return normalized.contains('pastilla') &&
        (normalized.contains('freno') || normalized == 'pastillas');
  }

  Future<void> _loadCurrentRequestLocation() async {
    final user = ref.read(authProvider).user;
    final usesSavedLocation = user?.role.usesSavedLocationForSearch ?? false;
    if (usesSavedLocation ||
        _requestedCurrentLocation ||
        _requestLocation != null) {
      return;
    }

    _requestedCurrentLocation = true;
    setState(() {
      _isLocatingRequest = true;
      _requestLocationError = null;
    });

    final found =
        await ref.read(userLocationProvider.notifier).updateLocation();
    if (!mounted) return;
    final position = ref.read(userLocationProvider).valueOrNull;
    if (!found || position == null) {
      setState(() {
        _isLocatingRequest = false;
        _requestLocationError =
            'No pudimos obtener tu ubicación actual. Puedes elegirla en el mapa.';
      });
      return;
    }

    final label =
        await ref.read(locationServiceProvider).getAddressFromCoordinates(
              position.latitude,
              position.longitude,
            );
    if (!mounted) return;
    ref.read(isLocationSharedProvider.notifier).state = true;
    setState(() {
      _requestLocation = RequestLocationSelection(
        latitude: position.latitude,
        longitude: position.longitude,
        source: RequestLocationSource.gps,
        label: label,
      );
      _isLocatingRequest = false;
      _requestLocationError = null;
      _isDirty = true;
    });
  }

  Future<void> _prevStep() async {
    if (_currentStep > 1) {
      await _goToStep(_currentStep - 1);
      return;
    }
    // En el paso 1, salir descarta el vehículo ya elegido: confirmar antes
    // de perderlo silenciosamente.
    if (!_isDirty) {
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
          'Perderás los datos que ya seleccionaste para esta solicitud.',
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
      _isDirty = true;
      // Solo selecciona: avanzar de paso requiere tocar "Continuar",
      // igual que en los pasos 2 y 3.
    });
  }

  RequestLocationSeed _resolveEffectiveRequestLocation() {
    final isShared = ref.read(isLocationSharedProvider);
    final current = ref.read(userLocationProvider).valueOrNull;
    final user = ref.read(authProvider).user;
    final canUseTemporaryLocation =
        !(user?.role.usesSavedLocationForSearch ?? false);
    return resolveRequestLocationSeed(
      requestSelection: _requestLocation,
      gpsLatitude:
          canUseTemporaryLocation && isShared ? current?.latitude : null,
      gpsLongitude:
          canUseTemporaryLocation && isShared ? current?.longitude : null,
      profileLatitude: user?.latitude,
      profileLongitude: user?.longitude,
    );
  }

  Future<void> _openRequestLocationPicker() async {
    final seed = _resolveEffectiveRequestLocation();

    final result = await RequestLocationPickerDialog.show(
      context,
      initialSelection: seed.selection,
      initialCenter: seed.center,
    );
    if (result != null && mounted) {
      setState(() {
        _requestLocation = result;
        _isDirty = true;
      });
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final vehicle = _selectedVehicle;
    final subcat = _selectedSubcategory;
    final partType = _selectedPartType;
    final details = _detailsController.text.trim();
    final requestLocation = _resolveEffectiveRequestLocation().selection;

    if (vehicle == null ||
        subcat == null ||
        partType == null ||
        details.isEmpty ||
        requestLocation == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      String userCarId = vehicle.id;
      if (vehicle.id.startsWith('temp-')) {
        if (_temporaryModelId == null) {
          setState(() => _submitError = 'No identificamos el modelo elegido.');
          return;
        }
        final addResult = await ref.read(addCarToGarageUseCaseProvider)(
          modelId: _temporaryModelId!,
          year: vehicle.year,
          motor: vehicle.motor,
        );
        if (!mounted) return;
        final registeredCar = addResult.fold((failure) {
          setState(() {
            _submitError = 'No pudimos guardar el vehículo: ${failure.message}';
          });
          return null;
        }, (car) {
          ref.read(authProvider.notifier).addUserCar(car);
          return car;
        });
        if (registeredCar == null) return;
        setState(() {
          _selectedVehicle = registeredCar;
          _temporaryModelId = null;
        });
        userCarId = registeredCar.id;
      }

      await ref.read(searchRequestNotifierProvider.notifier).submitSearch(
            userCarId: userCarId,
            subcategoryId: subcat.id,
            details: details,
            partType: partType,
            fotoUrl: _selectedImagePath,
            lat: requestLocation.latitude,
            lon: requestLocation.longitude,
          );

      if (!mounted) return;
      final state = ref.read(searchRequestNotifierProvider);
      if (state.status == SearchRequestStatus.success) {
        _showSuccessDialog();
      } else {
        setState(() {
          _submitError = state.errorMessage ??
              'No pudimos enviar la solicitud. Intenta nuevamente.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => PopScope(
        canPop: false,
        child: SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.9,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Builder(builder: (context) {
                    final reduceMotion =
                        MediaQuery.disableAnimationsOf(context);
                    final icon = Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                          color: AppColors.primaryMuted,
                          shape: BoxShape.circle),
                      child: const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary, size: 44),
                    );
                    if (reduceMotion) return icon;
                    return TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutBack,
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) =>
                          Transform.scale(scale: value, child: child),
                      child: icon,
                    );
                  }),
                  const SizedBox(height: 24),
                  Text('Solicitud enviada', style: AppTypography.h1),
                  const SizedBox(height: 12),
                  Text(
                    'Ya estamos buscando tiendas cercanas. Te avisaremos cuando recibas respuestas.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  if (_selectedVehicle != null &&
                      _selectedSubcategory != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        '${_selectedVehicle!.brand} '
                        '${_selectedVehicle!.model} · '
                        '${_selectedSubcategory!.name}',
                        textAlign: TextAlign.center,
                        style: AppTypography.title,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close Success
                        Navigator.pop(context); // Close Wizard
                        ref
                            .read(searchRequestNotifierProvider.notifier)
                            .reset();
                        ref.invalidate(consumerRequestsProvider);
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
          ),
        ),
      ),
    );
  }

  String get _primaryLabel {
    if (_currentStep < 3) return 'Continuar';
    if (_isSubmitting) return 'Enviando solicitud…';
    return _submitError == null ? 'Enviar solicitud' : 'Reintentar envío';
  }

  bool get _canUsePrimaryAction {
    switch (_currentStep) {
      case 1:
        return _selectedVehicle != null;
      case 2:
        return _selectedSubcategory != null && _selectedPartType != null;
      default:
        return _resolveEffectiveRequestLocation().selection != null &&
            _detailsController.text.trim().isNotEmpty;
    }
  }

  Future<void> _handlePrimaryAction() async {
    if (!_canUsePrimaryAction || _isSubmitting) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (_currentStep < 3) {
      await _goToStep(_currentStep + 1);
      return;
    }
    await _submit();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);
    ref.watch(isLocationSharedProvider);
    ref.watch(userLocationProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _prevStep();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _WizardHeader(step: _currentStep, onBack: _prevStep),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep(1),
                    _buildStep(2),
                    _buildStep(3),
                  ],
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _detailsController,
                builder: (context, _, __) => _WizardBottomBar(
                  label: _primaryLabel,
                  enabled: _canUsePrimaryAction,
                  loading: _isSubmitting,
                  errorMessage: _submitError,
                  onPressed: _handlePrimaryAction,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int step) {
    switch (step) {
      case 1:
        return _SparePartWizardStep1(
          key: const ValueKey('step1'),
          selectedCar: _selectedVehicle,
          onVehicleSelected: _onVehicleSelected,
        );
      case 2:
        return _SparePartWizardStep2(
          key: const ValueKey('step2'),
          selectedVehicle: _selectedVehicle,
          selectedCategory: _selectedCategory,
          selectedSubcategory: _selectedSubcategory,
          selectedPartType: _selectedPartType,
          onCategoryChanged: (cat, subcat) {
            setState(() {
              if (_selectedSubcategory?.id != subcat?.id) {
                _cbkPromptedSubcategoryId = null;
              }
              _selectedCategory = cat;
              _selectedSubcategory = subcat;
              _isDirty = true;
            });
          },
          onPartTypeChanged: (pt) {
            setState(() {
              _selectedPartType = pt;
              _isDirty = true;
            });
          },
          onEditVehicle: () => _goToStep(1),
        );
      case 3:
        // While GPS is resolving (or if it failed), do not briefly present a
        // saved/profile coordinate as though it were the consumer's current
        // position. Manual selection remains available after an error.
        final effectiveLocation =
            _isLocatingRequest || _requestLocationError != null
                ? _requestLocation
                : _resolveEffectiveRequestLocation().selection;
        return SparePartWizardStep3(
          key: const ValueKey('step3'),
          selectedVehicle: _selectedVehicle,
          selectedCategory: _selectedCategory,
          selectedSubcategory: _selectedSubcategory,
          selectedPartType: _selectedPartType,
          detailsController: _detailsController,
          selectedImagePath: _selectedImagePath,
          requestLocation: effectiveLocation,
          isLocatingLocation: _isLocatingRequest,
          locationError: _requestLocationError,
          onLocationTap: _openRequestLocationPicker,
          onEditVehicle: () => _goToStep(1),
          onEditPart: () => _goToStep(2),
          onImagePicked: (path) {
            setState(() {
              _selectedImagePath = path;
              _isDirty = true;
            });
          },
        );
      default:
        return const SizedBox();
    }
  }
}
