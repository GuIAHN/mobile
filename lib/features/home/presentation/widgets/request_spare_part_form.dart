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
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../../vehicles/domain/entities/user_car.dart';
import '../../../vehicles/presentation/providers/vehicle_providers.dart';
import '../../../../core/utils/async_error_listener.dart';
import '../../../vehicles/presentation/widgets/vehicle_selection_modal.dart';
import '../providers/home_providers.dart';
import '../../../../core/domain/enums/part_type.dart';
import '../../../../core/utils/extensions.dart';
import '../../../vehicles/presentation/widgets/garage_vehicle_selector_sheet.dart';
import '../../../../core/services/location_service.dart';

class RequestSparePartForm extends ConsumerStatefulWidget {
  final VoidCallback? onSubmitted;

  const RequestSparePartForm({
    super.key,
    this.onSubmitted,
  });

  @override
  ConsumerState<RequestSparePartForm> createState() => _RequestSparePartFormState();
}

class _RequestSparePartFormState extends ConsumerState<RequestSparePartForm> {
  final _detailsController = TextEditingController();

  Category? _selectedCategory;
  Category? _selectedSubcategory;
  PartType? _selectedPartType;

  String? _selectedImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
    if (globalVehicle == null || selectedSubcategory == null || selectedPartType == null) return;

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
            const Icon(Icons.storefront_rounded, size: 48, color: AppColors.primary),
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
    final hasCategory = _selectedCategory != null && _selectedSubcategory != null;
    final hasVehicle = globalVehicle != null;
    final hasPartType = _selectedPartType != null;
    final isValid = hasCategory && hasVehicle && hasPartType;

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
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),

          // Campo 1: Categoría y Subcategoría de Repuesto
          _buildLabel('CATEGORÍA DE REPUESTO *'),
          const SizedBox(height: 6),
          _SelectorField(
            value: _selectedCategory != null && _selectedSubcategory != null
                ? '${_selectedCategory!.name}  ▸  ${_selectedSubcategory!.name}'
                : null,
            placeholder: 'Selecciona categoría y subcategoría',
            onTap: () async {
              final result = await showModalBottomSheet<_CategorySubcategoryResult>(
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

          // Campo 3: Selector de vehículo (Requerido para todos, con comportamiento diferente según rol)
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
                value: globalVehicle != null ? 'Otro: ${globalVehicle.brand} ${globalVehicle.model}' : null,
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
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    height: 102,
                    decoration: BoxDecoration(
                      color: esSeleccionado ? AppColors.primaryMuted : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: esSeleccionado ? AppColors.primary : AppColors.border,
                        width: esSeleccionado ? 1.5 : 1.0,
                      ),
                      boxShadow: esSeleccionado ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ] : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          type.icon,
                          color: esSeleccionado ? AppColors.primary : AppColors.textSecondary,
                          size: 22,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          type.label,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: esSeleccionado ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          type.description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w500,
                            color: esSeleccionado ? AppColors.primary.withValues(alpha: 0.8) : AppColors.textSecondary,
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

          // Campo 4: Detalles adicionales (Opcional)
          _buildLabel('DETALLES ADICIONALES (OPCIONAL)'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _detailsController,
            hint: 'Ej. Alternador para motor 1.8L, lado derecho, marca Denso...',
            maxLines: 2,
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
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
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
                fontWeight: controller.text.isNotEmpty ? FontWeight.w600 : FontWeight.w400,
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
  final IconData? icon;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;
  final bool enabled;

  const _SelectorField({
    this.icon,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    final isLongText = hasValue && (value!.contains('▸') || value!.length > 28);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasValue ? AppColors.primary : AppColors.border,
            width: hasValue ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon!,
                size: 20,
                color: hasValue ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                value ?? placeholder,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: isLongText ? 13 : 14.5,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                  color: hasValue ? AppColors.textPrimary : AppColors.textDisabled,
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
    );
  }
}

// ===== Hoja de Selección de Categoría y Subcategoría Combinada =====
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
  Category? _selectedCategory;
  String _filtro = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedCategory == null) {
      // 1. Mostrar categorías principales
      final categoriesAsync = ref.watch(categoriesProvider);
      return _buildSheetLayout(
        titulo: 'Selecciona la categoría',
        asyncValue: categoriesAsync,
        onItemSelected: (category) {
          setState(() {
            _selectedCategory = category;
            _filtro = '';
            _searchController.clear();
          });
        },
      );
    } else {
      // 2. Mostrar subcategorías de la categoría seleccionada
      final subcategoriesAsync =
          ref.watch(subcategoriesProvider(_selectedCategory!.id));
      return _buildSheetLayout(
        titulo: _selectedCategory!.name,
        asyncValue: subcategoriesAsync,
        showBackButton: true,
        onBackPressed: () {
          setState(() {
            _selectedCategory = null;
            _filtro = '';
            _searchController.clear();
          });
        },
        onItemSelected: (subcategory) {
          Navigator.pop(
            context,
            _CategorySubcategoryResult(
              category: _selectedCategory!,
              subcategory: subcategory,
            ),
          );
        },
      );
    }
  }

  Widget _buildSheetLayout({
    required String titulo,
    required AsyncValue<List<Category>> asyncValue,
    required ValueChanged<Category> onItemSelected,
    bool showBackButton = false,
    VoidCallback? onBackPressed,
  }) {
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
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle de arrastre
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
          
          // Fila del título y botón atrás
          Row(
            children: [
              if (showBackButton) ...[
                GestureDetector(
                  onTap: onBackPressed,
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
                  titulo,
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
          
          // Campo de búsqueda
          TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _filtro = val;
              });
            },
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14.5,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Buscar...',
              hintStyle: GoogleFonts.hankenGrotesk(
                color: AppColors.textDisabled,
                fontSize: 14.5,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
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

          // Listado
          Expanded(
            child: asyncValue.when(
              data: (opciones) {
                final opcionesFiltradas = opciones.where((op) {
                  return op.name.toLowerCase().contains(_filtro.toLowerCase());
                }).toList();

                if (opcionesFiltradas.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'No se encontraron resultados',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: opcionesFiltradas.length,
                  itemBuilder: (_, i) {
                    final op = opcionesFiltradas[i];
                    final isActivo = op.id == widget.initialSubcategory?.id ||
                        op.id == widget.initialCategory?.id;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: Text(
                        op.name,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 15,
                          fontWeight: isActivo ? FontWeight.w800 : FontWeight.w500,
                          color: isActivo ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      trailing: isActivo
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                              size: 20,
                            )
                          : const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                      onTap: () => onItemSelected(op),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error al cargar: $err',
                    style: GoogleFonts.hankenGrotesk(
                      color: AppColors.error,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySubcategoryResult {
  final Category category;
  final Category subcategory;

  const _CategorySubcategoryResult({
    required this.category,
    required this.subcategory,
  });
}

