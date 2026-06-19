import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/brand.dart';
import '../providers/register_vehicles_provider.dart';
import '../providers/vehicle_providers.dart';

class RegisterVehiclesPage extends ConsumerStatefulWidget {
  const RegisterVehiclesPage({super.key});

  @override
  ConsumerState<RegisterVehiclesPage> createState() => _RegisterVehiclesPageState();
}

class _RegisterVehiclesPageState extends ConsumerState<RegisterVehiclesPage> {
  Brand? _selectedBrand;
  String? _modeloName;
  int? _anio;

  bool _isSaving = false;

  bool get _formCompleto => _selectedBrand != null && _modeloName != null && _anio != null;

  // ===== Selector Bottom Sheet de GuIA / Veloce Automotive =====
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
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 26,
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.78,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /* Handle de arrastre */
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: AppColors.textDisabled,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Text(
                    titulo,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  /* Buscador */
                  TextField(
                    onChanged: (val) {
                      setModalState(() {
                        filtro = val;
                      });
                    },
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buscar...',
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
                        horizontal: 16,
                        vertical: 13,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: opcionesFiltradas.isEmpty
                        ? Center(
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
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: opcionesFiltradas.length,
                            itemBuilder: (_, i) {
                              final op = opcionesFiltradas[i];
                              final activo = op == seleccionado;
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
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

  void _agregarVehiculo() {
    if (!_formCompleto) return;

    final models = ref.read(brandModelsProvider(_selectedBrand!.id)).value ?? [];
    final selectedModel = models.firstWhere((m) => m.name == _modeloName && m.year == _anio);

    ref.read(registerVehiclesProvider.notifier).addUserCar(
          brand: _selectedBrand!.name,
          model: _modeloName!,
          year: _anio!,
          modelId: selectedModel.id,
        );
    setState(() {
      _selectedBrand = null;
      _modeloName = null;
      _anio = null;
    });
  }

  Future<void> _finishRegistration() async {
    final vehiculos = ref.read(registerVehiclesProvider);
    if (vehiculos.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    final repository = ref.read(vehicleRepositoryProvider);

    for (final v in vehiculos) {
      final result = await repository.addCarToGarage(
        modelId: v.modelId,
      );
      result.fold(
        (failure) {
          print('Error al guardar vehículo ${v.brand} ${v.model}: ${failure.message}');
        },
        (success) {
          print('Vehículo guardado exitosamente: ${success.id}');
        },
      );
    }

    setState(() {
      _isSaving = false;
    });

    ref.read(authProvider.notifier).logout().then((_) {
      if (!mounted) return;
      ref.read(registerVehiclesProvider.notifier).clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Registro completado. Por favor inicia sesión.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
      context.go(RouteNames.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(brandsProvider);
    if (_selectedBrand != null) {
      ref.watch(brandModelsProvider(_selectedBrand!.id));
    }

    final vehiculos = ref.watch(registerVehiclesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: LayoutBuilder(
              builder: (context, viewportConstraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: viewportConstraints.maxHeight - 32,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _appBar(),
                          const SizedBox(height: 16),
                          _indicadorPasos(),
                          const SizedBox(height: 24),
                          _tituloPaso(),
                          const SizedBox(height: 24),

                          // Formulario
                          _FieldLabel('MARCA'),
                          _SelectorField(
                            icon: Icons.directions_car_outlined,
                            value: _selectedBrand?.name,
                            placeholder: 'Selecciona la marca',
                            onTap: () async {
                              final brandsState = ref.read(brandsProvider);
                              final brands = brandsState.value ?? [];
                              if (brands.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Cargando marcas de la API...')),
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
                              }
                            },
                          ),

                          _FieldLabel('MODELO'),
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
                              }
                            },
                          ),

                          _FieldLabel('AÑO'),
                          _SelectorField(
                            icon: Icons.calendar_today_outlined,
                            value: _anio?.toString(),
                            placeholder: 'Selecciona el año',
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
                              if (r != null) setState(() => _anio = r);
                            },
                          ),

                          const SizedBox(height: 8),
                          _botonAgregar(),

                          const SizedBox(height: 28),

                          // Lista de autos
                          Row(
                            children: [
                              _FieldLabel('TUS VEHÍCULOS'),
                              const SizedBox(width: 8),
                              if (vehiculos.isNotEmpty) _BadgeCount(vehiculos.length),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (vehiculos.isEmpty)
                            const _EmptyUserCarsCard()
                          else
                            ...vehiculos.asMap().entries.map((entry) {
                              return _UserCarItemCard(
                                brand: entry.value.brand,
                                model: entry.value.model,
                                year: entry.value.year,
                                onDelete: () {
                                  ref.read(registerVehiclesProvider.notifier).removeUserCar(entry.key);
                                },
                              );
                            }),

                          const Spacer(),
                          const SizedBox(height: 32),
                          _footer(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _appBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go(RouteNames.registerUser),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Mi Garage',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        const Icon(
          Icons.help_outline,
          color: AppColors.textSecondary,
          size: 20,
        ),
      ],
    );
  }

  Widget _indicadorPasos() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'PASO 2 DE 2',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: AppColors.textSecondary,
          ),
        ),
        Row(
          children: List.generate(2, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 28,
              height: 5,
              margin: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                color: i < 2 ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _tituloPaso() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mi Garage',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Paso 2 de 2: Agrega los vehículos que quieres gestionar. Puedes añadir más después.',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 13,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _botonAgregar() {
    final enabled = _formCompleto;
    return _PressableScale(
      onTap: enabled ? _agregarVehiculo : null,
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: enabled ? _agregarVehiculo : null,
          icon: const Icon(Icons.add, size: 18),
          label: Text(
            'AGREGAR VEHÍCULO',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            disabledForegroundColor: AppColors.textDisabled,
            side: BorderSide(
              color: enabled ? AppColors.primary : AppColors.border,
              width: 1.5,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    final vehiculos = ref.watch(registerVehiclesProvider);
    final enabled = vehiculos.isNotEmpty && !_isSaving;

    return _PressableScale(
      onTap: enabled ? _finishRegistration : null,
      child: SizedBox(
        width: double.infinity,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: ElevatedButton(
            onPressed: enabled ? _finishRegistration : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFD9DCE1),
              disabledForegroundColor: const Color(0xFF9AA0A8),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isSaving ? 'GUARDANDO VEHÍCULOS...' : 'FINALIZAR REGISTRO',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 8),
                _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check_circle_outline, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: AppColors.textSecondary,
        ),
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
                    fontSize: 16,
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

class _UserCarItemCard extends StatelessWidget {
  final String brand;
  final String model;
  final int year;
  final VoidCallback onDelete;

  const _UserCarItemCard({
    required this.brand,
    required this.model,
    required this.year,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.directions_car_rounded,
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
                  '$brand $model',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Año $year',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
              size: 22,
            ),
            tooltip: 'Eliminar',
          ),
        ],
      ),
    );
  }
}

class _EmptyUserCarsCard extends StatelessWidget {
  const _EmptyUserCarsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.no_crash_outlined,
            size: 36,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 10),
          Text(
            'Aún no has agregado vehículos',
            style: GoogleFonts.hankenGrotesk(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCount extends StatelessWidget {
  final int count;
  const _BadgeCount(this.count);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.hankenGrotesk(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _PressableScale({
    required this.child,
    this.onTap,
  });

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
