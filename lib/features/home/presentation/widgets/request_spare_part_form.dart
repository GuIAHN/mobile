import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../vehicles/domain/entities/brand.dart';
import '../../../vehicles/domain/entities/user_car.dart';
import '../../../vehicles/presentation/providers/vehicle_providers.dart';

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
  final _productController = TextEditingController();
  final _detailsController = TextEditingController();

  UserCar? _selectedGarageCar;
  bool _isOtherVehicle = false;

  Brand? _selectedBrand;
  String? _modeloName;
  int? _anio;

  bool _hasPhoto = false;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _productController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _productController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      final hasProduct = _productController.text.trim().isNotEmpty;
      final hasVehicle = (!_isOtherVehicle && _selectedGarageCar != null) ||
          (_isOtherVehicle &&
              _selectedBrand != null &&
              _modeloName != null &&
              _anio != null);
      _isValid = hasProduct && hasVehicle;
    });
  }

  // ===== Selector Bottom Sheet genérico =====
  Future<T?> _abrirSelector<T>({
    required String titulo,
    required List<T> opciones,
    required String Function(T) etiqueta,
    T? seleccionado,
  }) {
    String filtro = '';
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final opcionesFiltradas = opciones.where((op) {
              return etiqueta(op).toLowerCase().contains(filtro.toLowerCase());
            }).toList();

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
                    titulo,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Buscador para filtrar opciones rápidamente
                  TextField(
                    onChanged: (val) {
                      setModalState(() {
                        filtro = val;
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
                  Flexible(
                    child: opcionesFiltradas.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'No se encontraron resultados',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 13.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: opcionesFiltradas.length,
                            itemBuilder: (_, i) {
                              final op = opcionesFiltradas[i];
                              final activo = op == seleccionado;
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                title: Text(
                                  etiqueta(op),
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 15,
                                    fontWeight: activo ? FontWeight.w800 : FontWeight.w500,
                                    color: activo ? AppColors.primary : AppColors.textPrimary,
                                  ),
                                ),
                                trailing: activo
                                    ? const Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.primary,
                                        size: 20,
                                      )
                                    : null,
                                onTap: () => Navigator.pop(context, op),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ===== Abrir selector de vehículo del Garaje =====
  void _abrirSelectorVehiculo(List<UserCar> garageCars) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // Autos del garaje
                    ...garageCars.map((car) {
                      final esSeleccionado = !_isOtherVehicle && _selectedGarageCar?.id == car.id;
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
                              color: esSeleccionado
                                  ? AppColors.primaryMuted
                                  : AppColors.grey100,
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
                              _isOtherVehicle = false;
                            });
                            _validateForm();
                            Navigator.pop(context);
                          },
                        ),
                      );
                    }),
                    
                    // Opción: Otro vehículo
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isOtherVehicle ? AppColors.primary : AppColors.border,
                          width: _isOtherVehicle ? 1.5 : 1.0,
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _isOtherVehicle ? AppColors.primaryMuted : AppColors.grey100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_circle_outline_rounded,
                            color: _isOtherVehicle ? AppColors.primary : AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          'Otro vehículo...',
                          style: GoogleFonts.hankenGrotesk(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            color: _isOtherVehicle ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Elegir marca y modelo desde cero',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: _isOtherVehicle
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedGarageCar = null;
                            _isOtherVehicle = true;
                          });
                          _validateForm();
                          Navigator.pop(context);
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
                  _productController.clear();
                  _detailsController.clear();
                  setState(() {
                    _selectedGarageCar = null;
                    _isOtherVehicle = false;
                    _selectedBrand = null;
                    _modeloName = null;
                    _anio = null;
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
    // Es un usuario convencional si no tiene un rol específico o si es de tipo CONSUMER
    final isConsumer = user == null || user.role == 'CONSUMER' || user.role == 'user';

    // Cargar vehículos del garaje
    final userCarsAsync = ref.watch(userCarsProvider);

    // Precargar marcas y modelos por si se selecciona "Otro de 0"
    ref.watch(brandsProvider);
    if (_selectedBrand != null) {
      ref.watch(brandModelsProvider(_selectedBrand!.id));
    }

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

          // Campo 1: Producto / Repuesto
          _buildLabel('REPUESTO QUE BUSCAS *'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _productController,
            hint: 'Ej. Kit de embrague, amortiguador delantero...',
            icon: Icons.search_outlined,
          ),
          const SizedBox(height: 18),

          // Campo 2: Selector de vehículo (Solo si es un CONSUMER convencional)
          if (isConsumer) ...[
            _buildLabel('VEHÍCULO PARA LA SOLICITUD *'),
            const SizedBox(height: 8),
            userCarsAsync.when(
              data: (garageCars) {
                final String valorMostrado;
                if (_isOtherVehicle) {
                  valorMostrado = 'Otro vehículo...';
                } else if (_selectedGarageCar != null) {
                  valorMostrado = '${_selectedGarageCar!.brand} ${_selectedGarageCar!.model} (${_selectedGarageCar!.year})';
                } else {
                  valorMostrado = 'Selecciona de tu garaje u otro';
                }

                return _SelectorField(
                  icon: Icons.directions_car_filled_outlined,
                  value: (_selectedGarageCar != null || _isOtherVehicle) ? valorMostrado : null,
                  placeholder: 'Selecciona un vehículo de tu garaje',
                  onTap: () => _abrirSelectorVehiculo(garageCars),
                );
              },
              loading: () => Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                    SizedBox(width: 12),
                    Text('Cargando tus vehículos...', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              error: (_, __) => _SelectorField(
                icon: Icons.directions_car_filled_outlined,
                value: _isOtherVehicle ? 'Otro vehículo...' : null,
                placeholder: 'Ingresa vehículo manual',
                onTap: () => _abrirSelectorVehiculo(const []),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Si seleccionó "+ Otro vehículo" (o si no es CONSUMER, por fallback)
          if (_isOtherVehicle || !isConsumer) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detalles del vehículo:',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Marca
                  _buildLabel('MARCA *'),
                  const SizedBox(height: 6),
                  _SelectorField(
                    icon: Icons.directions_car_outlined,
                    value: _selectedBrand?.name,
                    placeholder: 'Selecciona la marca',
                    onTap: () async {
                      final brandsState = ref.read(brandsProvider);
                      final brands = brandsState.value ?? [];
                      if (brands.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cargando marcas...')),
                        );
                        return;
                      }
                      final r = await _abrirSelector<Brand>(
                        titulo: 'Selecciona la marca',
                        opciones: brands,
                        etiqueta: (b) => b.name,
                        seleccionado: _selectedBrand,
                      );
                      if (r != null) {
                        setState(() {
                          _selectedBrand = r;
                          _modeloName = null;
                          _anio = null;
                        });
                        _validateForm();
                      }
                    },
                  ),

                  // Modelo
                  _buildLabel('MODELO *'),
                  const SizedBox(height: 6),
                  _SelectorField(
                    icon: Icons.commute_outlined,
                    value: _modeloName,
                    placeholder: _selectedBrand == null
                        ? 'Primero elige una marca'
                        : 'Selecciona el modelo',
                    enabled: _selectedBrand != null,
                    onTap: () async {
                      if (_selectedBrand == null) return;
                      final modelsState = ref.read(brandModelsProvider(_selectedBrand!.id));
                      final models = modelsState.value ?? [];
                      if (models.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cargando modelos...')),
                        );
                        return;
                      }
                      final distinctNames = models.map((m) => m.name).toSet().toList();
                      final r = await _abrirSelector<String>(
                        titulo: 'Modelos de ${_selectedBrand!.name}',
                        opciones: distinctNames,
                        etiqueta: (m) => m,
                        seleccionado: _modeloName,
                      );
                      if (r != null) {
                        setState(() {
                          _modeloName = r;
                          _anio = null;
                        });
                        _validateForm();
                      }
                    },
                  ),

                  // Año
                  _buildLabel('AÑO *'),
                  const SizedBox(height: 6),
                  _SelectorField(
                    icon: Icons.calendar_today_outlined,
                    value: _anio?.toString(),
                    placeholder: 'Selecciona el año',
                    enabled: _selectedBrand != null && _modeloName != null,
                    onTap: () async {
                      if (_selectedBrand == null || _modeloName == null) return;
                      final models = ref.read(brandModelsProvider(_selectedBrand!.id)).value ?? [];
                      final availableYears = models
                          .where((m) => m.name == _modeloName)
                          .map((m) => m.year)
                          .toSet()
                          .toList();
                      availableYears.sort((a, b) => b.compareTo(a));
                      final r = await _abrirSelector<int>(
                        titulo: 'Selecciona el año',
                        opciones: availableYears,
                        etiqueta: (a) => '$a',
                        seleccionado: _anio,
                      );
                      if (r != null) {
                        setState(() => _anio = r);
                        _validateForm();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Campo 3: Detalles adicionales (Opcional)
          _buildLabel('DETALLES ADICIONALES (OPCIONAL)'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _detailsController,
            hint: 'Ej. Lado derecho, número de chasis (VIN)...',
            icon: Icons.description_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 18),

          // Campo 4: Fotografía
          _buildLabel('FOTOGRAFÍA DE REFERENCIA (OPCIONAL)'),
          const SizedBox(height: 8),
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
                  style: _hasPhoto ? BorderStyle.solid : BorderStyle.solid,
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
          const SizedBox(height: 28),

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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
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
                    fontSize: 15,
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
      ),
    );
  }
}
