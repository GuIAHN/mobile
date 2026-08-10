import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/domain/enums/part_type.dart';
import '../../../../../shared/widgets/image_source_selector_sheet.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../core/services/location_service.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../vehicles/domain/entities/user_car.dart';
import '../../../../vehicles/domain/entities/brand.dart';
import '../../../../vehicles/presentation/providers/vehicle_providers.dart';
import '../../../../vehicles/presentation/widgets/vehicle_selection_modal.dart';
import '../../../../catalog/domain/entities/category.dart';
import '../../../../catalog/domain/entities/category_node.dart';
import '../../../../catalog/presentation/providers/catalog_providers.dart';
import '../../../../chat/presentation/providers/chat_providers.dart';
import '../../../domain/entities/home_filters.dart';
import '../../providers/home_providers.dart';
import '../form_parts/form_part_type_selector.dart';
import 'category_subcategory_selector_sheet.dart';
import '../../../../../shared/widgets/guia_map.dart';

// Parts
part 'spare_part_wizard_step1.dart';
part 'spare_part_wizard_step2.dart';
part 'spare_part_wizard_step3.dart';

class SparePartWizardPage extends ConsumerStatefulWidget {
  final VoidCallback? onSubmitted;

  const SparePartWizardPage({super.key, this.onSubmitted});

  static Future<void> show(BuildContext context, {VoidCallback? onSubmitted}) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SparePartWizardPage(onSubmitted: onSubmitted),
      ),
    );
  }

  @override
  ConsumerState<SparePartWizardPage> createState() => _SparePartWizardPageState();
}

class _SparePartWizardPageState extends ConsumerState<SparePartWizardPage> {
  int _currentStep = 1;

  UserCar? _selectedVehicle;
  String? _temporaryModelId;

  Category? _selectedCategory;
  Category? _selectedSubcategory;
  PartType? _selectedPartType;

  final _detailsController = TextEditingController();
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
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
        _currentStep++;
      }
    });
  }

  void _prevStep() {
    setState(() {
      if (_currentStep > 1) {
        _currentStep--;
      } else {
        Navigator.pop(context);
      }
    });
  }

  void _onVehicleSelected(UserCar car, [String? modelId]) {
    setState(() {
      _selectedVehicle = car;
      _temporaryModelId = modelId;
      _currentStep = 2; // Pass to category selection
    });
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

    if (vehicle == null || subcat == null || partType == null) return;

    String userCarId = vehicle.id;

    if (vehicle.id.startsWith('temp-')) {
      if (_temporaryModelId == null) {
        context.showSnackBar('Error: Modelo no identificado', isError: true);
        return;
      }
      _showLoadingOverlay();
      final addResult = await ref.read(addCarToGarageUseCaseProvider)(variantId: _temporaryModelId!);
      _hideLoadingOverlay();
      
      if (!mounted) return;
      final registeredCar = addResult.fold(
        (l) {
          context.showSnackBar('Error al registrar vehículo: ${l.message}', isError: true);
          return null;
        },
        (r) {
          ref.read(authProvider.notifier).addUserCar(r);
          return r;
        }
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
      subcategoryId: subcat.id,
      details: _detailsController.text,
      partType: partType,
      fotoUrl: _selectedImagePath,
      lat: lat,
      lon: lon,
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
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) => Transform.scale(scale: value, child: child),
              child: Container(
                width: 72, height: 72,
                decoration: const BoxDecoration(color: AppColors.primaryMuted, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 44),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '¡Solicitud Enviada!',
              style: GoogleFonts.hankenGrotesk(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              'Hemos enviado tu requerimiento de repuesto a las tiendas afiliadas más cercanas. Te notificaremos en la sección de Chats apenas recibas cotizaciones.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                ),
                child: Text('ENTENDIDO', style: GoogleFonts.hankenGrotesk(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2)),
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _prevStep,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: AppColors.textPrimary,
                  ),
                  Expanded(
                    child: Text(
                      'Paso $_currentStep de 3',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.hankenGrotesk(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 20), // Balance the icon button
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            // Content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentStep(),
              ),
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

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return _SparePartWizardStep1(
          key: const ValueKey('step1'),
          selectedCar: _selectedVehicle,
          onVehicleSelected: _onVehicleSelected,
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
        return _SparePartWizardStep3(
          key: const ValueKey('step3'),
          detailsController: _detailsController,
          selectedImagePath: _selectedImagePath,
          isOtroCategory: _selectedSubcategory?.id == 'other_subcategory_id',
          onImagePicked: (path) => setState(() => _selectedImagePath = path),
          onSubmit: _submit,
        );
      default:
        return const SizedBox();
    }
  }
}
