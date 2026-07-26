import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/image_source_selector_sheet.dart';
import '../../../../core/domain/enums/user_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../catalog/domain/entities/category.dart';
import '../../../catalog/domain/entities/category_node.dart';
import '../../../catalog/domain/entities/category_search_result.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../../vehicles/presentation/providers/vehicle_providers.dart';
import '../../../../core/utils/async_error_listener.dart';
import '../providers/home_providers.dart';
import '../../../../core/domain/enums/part_type.dart';
import '../../../../core/utils/extensions.dart';
import '../../../vehicles/presentation/widgets/garage_vehicle_selector_sheet.dart';
import '../../../../core/services/location_service.dart';
import '../../../chat/presentation/providers/chat_providers.dart';

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
      ref.read(searchVehicleModelIdProvider.notifier).state = result.modelId;
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
      final modelId = ref.read(searchVehicleModelIdProvider);
      if (modelId == null) {
        context.showSnackBar(
          'Error: No se pudo identificar el modelo del vehículo',
          isError: true,
        );
        return;
      }

      _showLoadingOverlay();
      final addCarResult = await ref.read(addCarToGarageUseCaseProvider)(
        modelId: modelId,
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
          ref.read(searchVehicleModelIdProvider.notifier).state = null;
          // Invalidate userCars so the list gets updated
          ref.invalidate(userCarsProvider);
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

    final String? mockFotoUrl = _selectedImagePath != null
        ? 'https://guiautomotriz.com/uploads/temp_${DateTime.now().millisecondsSinceEpoch}.jpg'
        : null;

    _showLoadingOverlay();
    await ref.read(searchRequestNotifierProvider.notifier).submitSearch(
          userCarId: userCarId,
          subcategoryId: selectedSubcategory.id,
          details: _detailsController.text,
          partType: selectedPartType,
          fotoUrl: mockFotoUrl,
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
            Container(
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
                  ref.read(searchVehicleModelIdProvider.notifier).state = null;
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
    // Escuchar el estado de autenticación y los vehículos de garaje
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

    // Cargar vehículos del garaje
    ref.listenAsyncError(userCarsProvider, context);
    final userCarsAsync = ref.watch(userCarsProvider);

    final globalVehicle = ref.watch(searchVehicleProvider);
    final hasCategory =
        _selectedCategory != null && _selectedSubcategory != null;
    final hasVehicle = globalVehicle != null;
    final hasPartType = _selectedPartType != null;
    final needsDetails = _isOtroCategory;
    final hasRequiredDetails =
        !needsDetails || _detailsController.text.trim().isNotEmpty;
    final isValid =
        hasCategory && hasVehicle && hasPartType && hasRequiredDetails;
    final completedSteps =
        (hasVehicle ? 1 : 0) + (hasCategory ? 1 : 0) + (hasPartType ? 1 : 0);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado de la solicitud
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primaryMuted,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.settings_suggest_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solicita tu Repuesto',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Cotiza al instante con las tiendas cercanas',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _StepProgressBadge(completed: completedSteps, total: 3),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: completedSteps / 3),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 4,
                backgroundColor: AppColors.grey100,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),

          // Campo 1: Selector de vehículo (Requerido para todos, con comportamiento diferente según rol)
          _buildLabel('VEHÍCULO PARA LA SOLICITUD *'),
          const SizedBox(height: 6),
          if (isConsumer) ...[
            userCarsAsync.when(
              data: (garageCars) {
                final String valorMostrado;
                if (globalVehicle != null) {
                  if (globalVehicle.id.startsWith('temp-')) {
                    valorMostrado =
                        'Otro: ${globalVehicle.brand} ${globalVehicle.model} (${globalVehicle.year})';
                  } else {
                    valorMostrado =
                        '${globalVehicle.brand} ${globalVehicle.model} (${globalVehicle.year})';
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
          const SizedBox(height: 12),

          // Campo 2: Categoría y Subcategoría de Repuesto
          _buildLabel('CATEGORÍA DE REPUESTO *'),
          const SizedBox(height: 6),
          _SelectorField(
            value: _categorySelectorValue(),
            placeholder: 'Selecciona categoría y subcategoría',
            onTap: () async {
              final result =
                  await showModalBottomSheet<_CategorySubcategoryResult>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                barrierColor: Colors.black.withValues(alpha: 0.4),
                builder: (_) => _CategorySubcategorySelectorSheet(
                  initialCategory: _selectedCategory,
                  initialSubcategory: _selectedSubcategory,
                ),
              );
              if (result != null) {
                setState(() {
                  _selectedCategory = result.category;
                  _selectedSubcategory = result.subcategory;
                });
              }
            },
          ),
          const SizedBox(height: 12),

          // Campo 3.5: Tipo de repuesto (Requerido)
          _buildLabel('TIPO DE REPUESTO *'),
          const SizedBox(height: 8),
          Row(
            children: PartType.values.map((type) {
              final esSeleccionado = _selectedPartType == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPartType = type;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    height: 102,
                    decoration: BoxDecoration(
                      color: esSeleccionado
                          ? AppColors.primaryMuted
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: esSeleccionado
                            ? AppColors.primary
                            : AppColors.border,
                        width: esSeleccionado ? 1.5 : 1.0,
                      ),
                      boxShadow: esSeleccionado
                          ? [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          type.icon,
                          color: esSeleccionado
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 22,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          type.label,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: esSeleccionado
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          type.description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w500,
                            color: esSeleccionado
                                ? AppColors.primary.withValues(alpha: 0.8)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Campo 4: Detalles adicionales (obligatorio si la categoría es "Otro")
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
                    size: 13, color: AppColors.primary),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Cuéntanos qué repuesto necesitas, ya que no coincide con ninguna categoría del catálogo.',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
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
          const SizedBox(height: 12),

          // Campo 5: Fotografía
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
                          child: Image.file(
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
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Presiona para adjuntar foto',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 20),

          // Botón de Enviar Solicitud
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isValid ? _onSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.grey200,
                disabledForegroundColor: AppColors.textDisabled,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                elevation: isValid ? 6 : 0,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ENVIAR SOLICITUD',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.send_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.hankenGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildLoadingField(String message) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
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
      padding: const EdgeInsets.symmetric(horizontal: 14),
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

class _StepProgressBadge extends StatelessWidget {
  final int completed;
  final int total;

  const _StepProgressBadge({required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final isComplete = completed >= total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isComplete ? AppColors.successLight : AppColors.grey100,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '$completed/$total',
        style: GoogleFonts.hankenGrotesk(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: isComplete ? AppColors.success : AppColors.textSecondary,
        ),
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
                Expanded(
                  child: Text(
                    value ?? placeholder,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: isLongText ? 13 : 14.5,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
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

// ===== Hoja de Selección de Categoría y Subcategoría — Búsqueda Unificada =====
class _CategorySubcategorySelectorSheet extends ConsumerStatefulWidget {
  final Category? initialCategory;
  final Category? initialSubcategory;

  const _CategorySubcategorySelectorSheet({
    this.initialCategory,
    this.initialSubcategory,
  });

  @override
  ConsumerState<_CategorySubcategorySelectorSheet> createState() =>
      _CategorySubcategorySelectorSheetState();
}

class _CategorySubcategorySelectorSheetState
    extends ConsumerState<_CategorySubcategorySelectorSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _isDebouncing = false;
  // Navegación de nivel: null = mostrar raíces, != null = mostrar hijos de ese nodo
  _CategoryNodeNav? _navNode;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String val) {
    // Reset nav when user starts typing
    if (_navNode != null && val.isNotEmpty) {
      setState(() => _navNode = null);
    }
    final trimmed = val.trim();
    if (trimmed.length < 2) {
      setState(() {
        _query = '';
        _isDebouncing = false;
      });
      return;
    }

    setState(() => _isDebouncing = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _query = trimmed;
        _isDebouncing = false;
      });
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _query = '';
      _isDebouncing = false;
    });
  }

  /// Resolves the selection to (category, subcategory) and pops.
  /// If [node] has children, it's a parent/intermediate category → navigate into it to select subcategories.
  /// Only leaf nodes (nodes without children) can be selected as final subcategories.
  void _onNodeTapped(CategoryNode node, List<CategoryNode> tree, {bool fromSearch = false}) {
    if (node.children.isNotEmpty) {
      // Navigate one level deeper to show subcategories
      setState(() {
        _navNode = _CategoryNodeNav(node: node, parent: _navNode);
        _query = '';
        _searchController.clear();
      });
      return;
    }

    // Resolve parent category + subcategory for the form contract
    final Category category;
    final Category subcategory;

    if (node.parentId == null) {
      // Root with no children selected directly — treat as both cat and subcat
      category = Category(id: node.id, name: node.name);
      subcategory = Category(id: node.id, name: node.name, parentId: null);
    } else {
      // Find root ancestor to use as category
      final root = _findRoot(tree, node);
      category = Category(id: root.id, name: root.name);
      subcategory = Category(id: node.id, name: node.name, parentId: node.parentId);
    }

    Navigator.pop(
      context,
      _CategorySubcategoryResult(category: category, subcategory: subcategory),
    );
  }

  CategoryNode _findRoot(List<CategoryNode> tree, CategoryNode target) {
    for (final root in tree) {
      if (root.id == target.id) return root;
      final found = _findInChildren(root, target);
      if (found != null) return root;
    }
    return target;
  }

  CategoryNode? _findInChildren(CategoryNode current, CategoryNode target) {
    if (current.id == target.id) return current;
    for (final child in current.children) {
      final found = _findInChildren(child, target);
      if (found != null) return found;
    }
    return null;
  }

  void _onOtroSelected() {
    const otroCategory = Category(id: 'f4ff2288-c7bc-4c42-b0ee-0e66a46e0395', name: 'Otro');
    Navigator.pop(
      context,
      const _CategorySubcategoryResult(
        category: otroCategory,
        subcategory: Category(
          id: '4340eca0-6410-414c-9655-e91711666860',
          name: 'Otro',
          parentId: 'f4ff2288-c7bc-4c42-b0ee-0e66a46e0395',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final treeAsync = ref.watch(categoryTreeProvider);
    final searchUseCase = ref.watch(searchCategoriesUseCaseProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 26,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ───────────────────────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),

          // ── Header ───────────────────────────────────────────────────────
          Row(
            children: [
              if (_navNode != null) ...[
                GestureDetector(
                  onTap: () => setState(() {
                    _navNode = _navNode?.parent;
                    _query = '';
                    _searchController.clear();
                  }),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 12, top: 4, bottom: 4),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
              Expanded(
                child: Text(
                  _navNode != null ? _navNode!.node.name : 'Categoría de Repuesto',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Barra de búsqueda ────────────────────────────────────────────
          TextField(
            controller: _searchController,
            onChanged: _onQueryChanged,
            autofocus: false,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14.5,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Buscar categoría o subcategoría...',
              hintStyle: GoogleFonts.hankenGrotesk(
                color: AppColors.textDisabled,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? _isDebouncing
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: _clearSearch,
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Contenido principal ──────────────────────────────────────────
          Expanded(
            child: treeAsync.when(
              loading: () => _buildSkeleton(),
              error: (err, _) => _buildError(() => ref.invalidate(categoryTreeProvider)),
              data: (tree) {
                final rawText = _searchController.text.trim();
                if (rawText.length == 1) {
                  return _buildEmptyState(
                    'Ingresa al menos 2 caracteres para iniciar la búsqueda.',
                  );
                }

                // En modo búsqueda activa
                if (_query.isNotEmpty) {
                  final results = searchUseCase.call(tree, _query);
                  return _buildSearchResults(results, tree);
                }

                // En modo navegación de nodo
                if (_navNode != null) {
                  return _buildNodeChildren(_navNode!.node.children, tree);
                }

                // Estado inicial: mostrar raíces
                return _buildRootGrid(tree);
              },
            ),
          ),

          const SizedBox(height: 12),

          // ── Botón "Otro" (siempre visible) ────────────────────────────────
          Semantics(
            button: true,
            label: 'Otro / no encuentro mi categoría',
            child: Material(
              color: AppColors.primaryMuted,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _onOtroSelected,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Otro / no encuentro mi categoría',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isOtroCategoryNode(String name) {
    final n = name.trim().toLowerCase();
    return n == 'otro' ||
        n == 'otra' ||
        n == 'otros' ||
        n == 'otras' ||
        n.startsWith('otro /') ||
        n.startsWith('otra /') ||
        n.startsWith('otro (');
  }

  // ── Grid de categorías raíz ──────────────────────────────────────────────
  Widget _buildRootGrid(List<CategoryNode> tree) {
    final filteredTree = tree
        .where((node) => !_isOtroCategoryNode(node.name))
        .toList();

    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.8,
      ),
      itemCount: filteredTree.length,
      itemBuilder: (_, i) {
        final node = filteredTree[i];
        final isActive = node.id == widget.initialCategory?.id;
        return _RootCategoryTile(
          node: node,
          isActive: isActive,
          onTap: () => _onNodeTapped(node, tree),
        );
      },
    );
  }

  // ── Hijos de un nodo de navegación ──────────────────────────────────────
  Widget _buildNodeChildren(List<CategoryNode> children, List<CategoryNode> tree) {
    final filteredChildren = children
        .where((node) => !_isOtroCategoryNode(node.name))
        .toList();

    if (filteredChildren.isEmpty) {
      return _buildEmptyState('Esta categoría no tiene subcategorías.');
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: filteredChildren.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
      itemBuilder: (_, i) {
        final node = filteredChildren[i];
        final isActive = node.id == widget.initialSubcategory?.id;
        return _CategoryResultTile(
          name: node.name,
          breadcrumbLabel: '',
          isActive: isActive,
          hasChildren: node.children.isNotEmpty,
          query: '',
          onTap: () => _onNodeTapped(node, tree),
        );
      },
    );
  }

  // ── Resultados de búsqueda ───────────────────────────────────────────────
  Widget _buildSearchResults(List<_CategorySearchResultTyped> results, List<CategoryNode> tree) {
    // Filter: hide items named 'Otro'/'Otra'
    final filtered = results
        .where((r) => !_isOtroCategoryNode(r.node.name))
        .toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(
        'No se encontraron resultados para "$_query".\nPuedes usar "Otro" si no encuentras tu categoría.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Contador de resultados
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Padding(
            key: ValueKey(filtered.length),
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${filtered.length} resultado${filtered.length != 1 ? 's' : ''}',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
            itemBuilder: (_, i) {
              final r = filtered[i];
              final isActive = r.node.id == widget.initialSubcategory?.id;
              return _CategoryResultTile(
                name: r.node.name,
                breadcrumbLabel: r.breadcrumbLabel,
                isActive: isActive,
                hasChildren: r.node.children.isNotEmpty,
                query: _query,
                onTap: () => _onNodeTapped(r.node, tree, fromSearch: true),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Skeleton loader ──────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return Column(
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
    );
  }

  // ── Error state ──────────────────────────────────────────────────────────
  Widget _buildError(VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            'Error al cargar las categorías',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(
              'Reintentar',
              style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700),
            ),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────
  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tile de categoría raíz (grid) ─────────────────────────────────────────
class _RootCategoryTile extends StatefulWidget {
  final CategoryNode node;
  final bool isActive;
  final VoidCallback onTap;

  const _RootCategoryTile({
    required this.node,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_RootCategoryTile> createState() => _RootCategoryTileState();
}

class _RootCategoryTileState extends State<_RootCategoryTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isActive ? AppColors.primaryMuted : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isActive ? AppColors.primary : AppColors.border,
              width: widget.isActive ? 1.5 : 1.0,
            ),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.node.name,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    fontWeight: widget.isActive ? FontWeight.w800 : FontWeight.w600,
                    color: widget.isActive ? AppColors.primary : AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.node.children.isNotEmpty)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: widget.isActive ? AppColors.primary : AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tile de resultado de búsqueda / hijo de nodo ──────────────────────────
class _CategoryResultTile extends StatelessWidget {
  final String name;
  final String breadcrumbLabel;
  final bool isActive;
  final bool hasChildren;
  final String query;
  final VoidCallback onTap;

  const _CategoryResultTile({
    required this.name,
    required this.breadcrumbLabel,
    required this.isActive,
    required this.hasChildren,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HighlightedText(
                    text: name,
                    query: query,
                    baseStyle: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      color: isActive ? AppColors.primary : AppColors.textPrimary,
                    ),
                    highlightStyle: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  if (breadcrumbLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.subdirectory_arrow_right_rounded,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            breadcrumbLabel,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isActive)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20)
            else
              Icon(
                hasChildren
                    ? Icons.chevron_right_rounded
                    : Icons.arrow_forward_ios_rounded,
                color: AppColors.textSecondary,
                size: hasChildren ? 20 : 14,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Widget para texto con highlights ─────────────────────────────────────
class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle baseStyle;
  final TextStyle highlightStyle;

  const _HighlightedText({
    required this.text,
    required this.query,
    required this.baseStyle,
    required this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: baseStyle);
    }
    final lower = text.toLowerCase();
    final queryLower = query.toLowerCase();
    final index = lower.indexOf(queryLower);
    if (index == -1) {
      return Text(text, style: baseStyle);
    }

    return RichText(
      text: TextSpan(children: [
        if (index > 0)
          TextSpan(text: text.substring(0, index), style: baseStyle),
        TextSpan(
          text: text.substring(index, index + query.length),
          style: highlightStyle,
        ),
        if (index + query.length < text.length)
          TextSpan(
            text: text.substring(index + query.length),
            style: baseStyle,
          ),
      ]),
    );
  }
}

// ── Helper de navegación ──────────────────────────────────────────────────
class _CategoryNodeNav {
  final CategoryNode node;
  final _CategoryNodeNav? parent;
  const _CategoryNodeNav({required this.node, this.parent});
}

// ── Alias tipado para resultados de búsqueda ──────────────────────────────
// Reuse CategorySearchResult but with a local alias for clarity in this file
typedef _CategorySearchResultTyped = CategorySearchResult;

class _CategorySubcategoryResult {
  final Category category;
  final Category subcategory;

  const _CategorySubcategoryResult({
    required this.category,
    required this.subcategory,
  });
}

