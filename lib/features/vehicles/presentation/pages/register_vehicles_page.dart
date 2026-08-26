import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/register_vehicles_provider.dart';
import '../providers/vehicle_providers.dart';
import '../widgets/vehicle_selection_modal.dart';

class RegisterVehiclesPage extends ConsumerStatefulWidget {
  const RegisterVehiclesPage({super.key});

  @override
  ConsumerState<RegisterVehiclesPage> createState() =>
      _RegisterVehiclesPageState();
}

class _RegisterVehiclesPageState extends ConsumerState<RegisterVehiclesPage> {
  bool _isSaving = false;

  // Eliminado el Selector viejo

  // Eliminado el antiguo método _agregarVehiculo()

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
        year: v.year,
        motor: v.motor,
      );
      result.fold(
        (failure) {
          debugPrint(
            'Error al guardar vehículo ${v.brand} ${v.model}: '
            '${failure.message}',
          );
        },
        (success) {
          debugPrint('Vehículo guardado exitosamente: ${success.id}');
        },
      );
    }

    setState(() {
      _isSaving = false;
    });

    ref.read(authProvider.notifier).logout().then((_) {
      if (!mounted) return;
      ref.read(registerVehiclesProvider.notifier).clear();
      context.showSnackBar(
        'Registro completado. Por favor inicia sesión.',
        isSuccess: true,
      );
      context.go(RouteNames.login);
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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

                          // Botón para abrir el nuevo Modal
                          _botonAgregarModal(),

                          const SizedBox(height: 28),

                          // Lista de autos
                          Row(
                            children: [
                              const _FieldLabel('TUS VEHÍCULOS'),
                              const SizedBox(width: 8),
                              if (vehiculos.isNotEmpty)
                                _BadgeCount(vehiculos.length),
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
                                  ref
                                      .read(registerVehiclesProvider.notifier)
                                      .removeUserCar(entry.key);
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

  Widget _botonAgregarModal() {
    return _PressableScale(
      onTap: () async {
        // Muestra el modal interactivo
        final result = await VehicleSelectionModal.show(context);

        if (result != null) {
          // Si el usuario completó la selección, agregamos el vehículo
          ref.read(registerVehiclesProvider.notifier).addUserCar(
                brand: result.brand.name,
                model: result.modelName,
                year: result.year,
                modelId: result.modelId,
                motor: result.motor,
              );
        }
      },
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            final result = await VehicleSelectionModal.show(context);
            if (result != null) {
              ref.read(registerVehiclesProvider.notifier).addUserCar(
                    brand: result.brand.name,
                    model: result.modelName,
                    year: result.year,
                    modelId: result.modelId,
                    motor: result.motor,
                  );
            }
          },
          icon: const Icon(Icons.add, size: 18),
          label: Text(
            'AÑADIR VEHÍCULO',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(
              color: AppColors.primary,
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
                      color: AppColors.primary.withValues(alpha: 0.4),
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
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
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
            color: Colors.black.withValues(alpha: 0.04),
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
              color: AppColors.primary.withValues(alpha: 0.12),
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
        color: AppColors.primary.withValues(alpha: 0.12),
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
