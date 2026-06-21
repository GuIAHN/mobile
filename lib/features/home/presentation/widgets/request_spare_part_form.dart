import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../catalog/domain/entities/category.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../../vehicles/domain/entities/user_car.dart';
import '../../../vehicles/presentation/providers/vehicle_providers.dart';
import '../../../../core/utils/async_error_listener.dart';
import '../../../vehicles/presentation/widgets/vehicle_selection_modal.dart';

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

  UserCar? _selectedGarageCar;
  UserCar? _selectedManualCar; // Si se elige "Otro vehículo..."

  bool _hasPhoto = false;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      final hasCategory = _selectedCategory != null && _selectedSubcategory != null;
      final hasVehicle = _selectedGarageCar != null || _selectedManualCar != null;
      _isValid = hasCategory && hasVehicle;
    });
  }
  // ===== Abrir selector de vehículo del Garaje =====
  void _abrirSelectorVehiculo(List<UserCar> garageCars) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 26,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              Text(
                'Selecciona un vehículo',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    // Autos del garaje del usuario
                    ...garageCars.map((car) {
                      final esSeleccionado = _selectedGarageCar?.id == car.id;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: esSeleccionado ? AppColors.primary : AppColors.border,
                            width: esSeleccionado ? 1.5 : 1.0,
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: esSeleccionado ? AppColors.primaryMuted : AppColors.grey100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.directions_car_rounded,
                              color: esSeleccionado ? AppColors.primary : AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            '${car.brand} ${car.model}',
                            style: GoogleFonts.hankenGrotesk(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'Año ${car.year}',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: esSeleccionado
                              ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedGarageCar = car;
                              _selectedManualCar = null;
                            });
                            _validateForm();
                            Navigator.pop(context);
                          },
                        ),
                      );
                    }),
                    
                    // Opción: Registrar/Elegir otro vehículo (Flujo aparte en Sheet)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _selectedManualCar != null ? AppColors.primary : AppColors.border,
                          width: _selectedManualCar != null ? 1.5 : 1.0,
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _selectedManualCar != null ? AppColors.primaryMuted : AppColors.grey100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_circle_outline_rounded,
                            color: _selectedManualCar != null ? AppColors.primary : AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          'Otro vehículo...',
                          style: GoogleFonts.hankenGrotesk(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            color: _selectedManualCar != null ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Ingresar marca, modelo y año desde cero',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: _selectedManualCar != null
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                            : null,
                        onTap: () {
                          Navigator.pop(context); // Cierra el selector de garaje
                          _abrirDialogoOtroVehiculo(); // Abre el flujo aparte para marca/modelo/año
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===== Flujo Aparte: Registro de vehículo manual en Bottom Sheet =====
  void _abrirDialogoOtroVehiculo() async {
    final result = await VehicleSelectionModal.show(context);
    if (result != null) {
      final car = UserCar(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        brand: result.brand.name,
        model: result.modelName,
        year: result.year,
      );
      setState(() {
        _selectedManualCar = car;
        _selectedGarageCar = null;
      });
      _validateForm();
    }
  }

  void _onSubmit() {
    if (!_isValid) return;

    // Mostrar un diálogo/bottom sheet de éxito sumamente estético
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
                    _selectedGarageCar = null;
                    _selectedManualCar = null;
                    _hasPhoto = false;
                    _isValid = false;
                  });
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
    final isConsumer = user == null || user.role == 'CONSUMER' || user.role == 'user';

    // Cargar vehículos del garaje
    ref.listenAsyncError(userCarsProvider, context);
    final userCarsAsync = ref.watch(userCarsProvider);



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
            icon: Icons.category_outlined,
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
                _validateForm();
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
                if (_selectedManualCar != null) {
                  valorMostrado = 'Otro: ${_selectedManualCar!.brand} ${_selectedManualCar!.model} (${_selectedManualCar!.year})';
                } else if (_selectedGarageCar != null) {
                  valorMostrado = '${_selectedGarageCar!.brand} ${_selectedGarageCar!.model} (${_selectedGarageCar!.year})';
                } else {
                  valorMostrado = 'Selecciona de tu garaje u otro';
                }

                return _SelectorField(
                  icon: Icons.directions_car_filled_outlined,
                  value: (_selectedGarageCar != null || _selectedManualCar != null) ? valorMostrado : null,
                  placeholder: 'Selecciona un vehículo de tu garaje',
                  onTap: () {
                    if (garageCars.isEmpty) {
                      _abrirDialogoOtroVehiculo();
                    } else {
                      _abrirSelectorVehiculo(garageCars);
                    }
                  },
                );
              },
              loading: () => _buildLoadingField('Cargando tus vehículos...'),
              error: (_, __) => _SelectorField(
                icon: Icons.directions_car_filled_outlined,
                value: _selectedManualCar != null ? 'Otro: ${_selectedManualCar!.brand} ${_selectedManualCar!.model}' : null,
                placeholder: 'Ingresa vehículo manual',
                onTap: _abrirDialogoOtroVehiculo,
              ),
            ),
          ] else ...[
            _SelectorField(
              icon: Icons.directions_car_filled_outlined,
              value: _selectedManualCar != null
                  ? '${_selectedManualCar!.brand} ${_selectedManualCar!.model} (${_selectedManualCar!.year})'
                  : null,
              placeholder: 'Selecciona marca, modelo y año',
              onTap: _abrirDialogoOtroVehiculo,
            ),
          ],
          const SizedBox(height: 12),

          // Campo 4: Detalles adicionales (Opcional)
          _buildLabel('DETALLES ADICIONALES (OPCIONAL)'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _detailsController,
            hint: 'Ej. Alternador para motor 1.8L, lado derecho, marca Denso...',
            icon: Icons.description_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 12),

          // Campo 5: Fotografía
          _buildLabel('FOTOGRAFÍA DE REFERENCIA (OPCIONAL)'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              setState(() {
                _hasPhoto = !_hasPhoto;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: double.infinity,
              height: 90,
              decoration: BoxDecoration(
                color: _hasPhoto ? AppColors.primaryMuted : AppColors.grey50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _hasPhoto ? AppColors.primary : AppColors.border,
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _hasPhoto
                    ? [
                        const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'foto_repuesto_2026.jpg adjunta',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
                      ]
                    : [
                        const Icon(Icons.add_a_photo_outlined, color: AppColors.textSecondary, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Presiona para adjuntar foto',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Botón de Enviar Solicitud
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isValid ? _onSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.grey200,
                disabledForegroundColor: AppColors.textDisabled,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                elevation: _isValid ? 6 : 0,
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
    required IconData icon,
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
  final IconData icon;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;
  final bool enabled;

  const _SelectorField({
    required this.icon,
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
            Icon(
              icon,
              size: 20,
              color: hasValue ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
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

