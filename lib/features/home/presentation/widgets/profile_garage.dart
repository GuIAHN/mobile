import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../vehicles/domain/entities/brand.dart';
import '../../../vehicles/domain/entities/car_model.dart';
import '../../../vehicles/domain/entities/user_car.dart';
import '../../../vehicles/presentation/providers/vehicle_providers.dart';

class ProfileGarage extends ConsumerWidget {
  const ProfileGarage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userCarsAsync = ref.watch(userCarsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila Encabezado Garage
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_car_filled_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Mi Garage',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            _PressableScale(
              onTap: () => _abrirDialogoAgregarVehiculo(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Agregar',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Listado de Autos
        userCarsAsync.when(
          data: (cars) {
            if (cars.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.no_crash_outlined, size: 36, color: AppColors.textDisabled),
                    const SizedBox(height: 10),
                    Text(
                      'Aún no tienes vehículos en tu garage.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.hankenGrotesk(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: cars.map((car) => _buildGarageCarCard(car)).toList(),
            );
          },
          loading: () => Container(
            height: 90,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Error al cargar vehículos: $err',
              style: GoogleFonts.hankenGrotesk(
                color: AppColors.error,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGarageCarCard(UserCar car) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: AppColors.primaryMuted,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.directions_car_rounded,
            color: AppColors.primary,
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
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ===== Modal para Registrar/Agregar Vehículo a la API =====
  void _abrirDialogoAgregarVehiculo(BuildContext context, WidgetRef ref) {
    Brand? selectedBrand;
    String? selectedModel;
    int? selectedYear;
    bool isSaving = false;

    // Buscar helper genérico
    Future<T?> abrirSelectorLocal<T>({
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final formCompleto = selectedBrand != null && selectedModel != null && selectedYear != null;

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    'Registrar vehículo',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Agrega este vehículo a tu garage personal.',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Marca
                  _buildLabelField('MARCA *'),
                  const SizedBox(height: 6),
                  _SelectorField(
                    icon: Icons.directions_car_outlined,
                    value: selectedBrand?.name,
                    placeholder: 'Selecciona la marca',
                    onTap: () async {
                      final brandsState = ref.read(brandsProvider);
                      final brands = brandsState.value ?? [];
                      if (brands.isEmpty) return;

                      final r = await abrirSelectorLocal<Brand>(
                        titulo: 'Selecciona la marca',
                        opciones: brands,
                        etiqueta: (b) => b.name,
                        seleccionado: selectedBrand,
                      );
                      if (r != null) {
                        setModalState(() {
                          selectedBrand = r;
                          selectedModel = null;
                          selectedYear = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Modelo
                  _buildLabelField('MODELO *'),
                  const SizedBox(height: 6),
                  _SelectorField(
                    icon: Icons.commute_outlined,
                    value: selectedModel,
                    placeholder: selectedBrand == null
                        ? 'Primero elige una marca'
                        : 'Selecciona el modelo',
                    enabled: selectedBrand != null,
                    onTap: () async {
                      if (selectedBrand == null) return;
                      final modelsState = ref.read(brandModelsProvider(selectedBrand!.id));
                      final models = modelsState.value ?? [];
                      if (models.isEmpty) return;

                      final distinctNames = models.map((m) => m.name).toSet().toList();
                      final r = await abrirSelectorLocal<String>(
                        titulo: 'Modelos de ${selectedBrand!.name}',
                        opciones: distinctNames,
                        etiqueta: (m) => m,
                        seleccionado: selectedModel,
                      );
                      if (r != null) {
                        setModalState(() {
                          selectedModel = r;
                          selectedYear = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Año
                  _buildLabelField('AÑO *'),
                  const SizedBox(height: 6),
                  _SelectorField(
                    icon: Icons.calendar_today_outlined,
                    value: selectedYear?.toString(),
                    placeholder: 'Selecciona el año',
                    enabled: selectedBrand != null && selectedModel != null,
                    onTap: () async {
                      if (selectedBrand == null || selectedModel == null) return;
                      final models = ref.read(brandModelsProvider(selectedBrand!.id)).value ?? [];
                      final availableYears = models
                          .where((m) => m.name == selectedModel)
                          .map((m) => m.year)
                          .toSet()
                          .toList();
                      availableYears.sort((a, b) => b.compareTo(a));

                      final r = await abrirSelectorLocal<int>(
                        titulo: 'Selecciona el año',
                        opciones: availableYears,
                        etiqueta: (a) => '$a',
                        seleccionado: selectedYear,
                      );
                      if (r != null) {
                        setModalState(() {
                          selectedYear = r;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Botón Confirmar
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (formCompleto && !isSaving)
                          ? () async {
                              setModalState(() {
                                isSaving = true;
                              });

                              final addCarUseCase = ref.read(addCarToGarageUseCaseProvider);
                              final models = ref.read(brandModelsProvider(selectedBrand!.id)).value ?? [];
                              final selectedModelEntity = models.firstWhere(
                                (m) => m.name == selectedModel && m.year == selectedYear,
                              );

                              final result = await addCarUseCase(
                                modelId: selectedModelEntity.id,
                              );

                              result.fold(
                                (failure) {
                                  setModalState(() {
                                    isSaving = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${failure.message}'),
                                      backgroundColor: AppColors.error,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                (car) {
                                  ref.refresh(userCarsProvider);
                                  Navigator.pop(context); // Cierra bottom sheet
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('¡${car.brand} ${car.model} registrado exitosamente!'),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.grey200,
                        disabledForegroundColor: AppColors.textDisabled,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        elevation: formCompleto ? 4 : 0,
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'REGISTRAR VEHÍCULO',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
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

  Widget _buildLabelField(String text) {
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
}

// ===== Botón con efecto de escalado premium =====
class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _PressableScale({required this.child, this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null) setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        if (widget.onTap != null) setState(() => _isPressed = false);
      },
      onTapCancel: () {
        if (widget.onTap != null) setState(() => _isPressed = false);
      },
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ===== Selector Field para usar sin Padding fijo =====
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
    );
  }
}
