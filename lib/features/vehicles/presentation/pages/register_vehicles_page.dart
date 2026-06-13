import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/circular_back_button.dart';
import '../providers/register_vehicles_provider.dart';

class RegisterVehiclesPage extends ConsumerStatefulWidget {
  const RegisterVehiclesPage({super.key});

  @override
  ConsumerState<RegisterVehiclesPage> createState() => _RegisterVehiclesPageState();
}

class _RegisterVehiclesPageState extends ConsumerState<RegisterVehiclesPage> {
  // ===== Catálogo de vehículos (Mocks) =====
  final Map<String, List<String>> _catalogo = {
    'Toyota': ['Corolla', 'Hilux', 'Yaris', 'Fortuner', '4Runner', 'Camry'],
    'Chevrolet': ['Aveo', 'Spark', 'Optra', 'Cruze', 'Silverado', 'Tahoe'],
    'Ford': ['Fiesta', 'Focus', 'Explorer', 'F-150', 'EcoSport', 'Ranger'],
    'Hyundai': ['Accent', 'Elantra', 'Tucson', 'Santa Fe', 'Getz'],
    'Kia': ['Rio', 'Picanto', 'Sportage', 'Sorento', 'Cerato'],
    'Mitsubishi': ['Lancer', 'Montero', 'Outlander', 'L200', 'Signo'],
    'Volkswagen': ['Gol', 'Polo', 'Jetta', 'Tiguan', 'Amarok'],
    'Renault': ['Logan', 'Sandero', 'Duster', 'Kwid', 'Twingo'],
    'Chery': ['Arauca', 'Orinoco', 'Tiggo', 'QQ', 'X1'],
    'Jeep': ['Cherokee', 'Grand Cherokee', 'Wrangler', 'Compass', 'Renegade'],
  };

  late final List<int> _anios =
      List.generate(36, (i) => DateTime.now().year + 1 - i); // años: 2027 a 1992

  String? _marca;
  String? _modelo;
  int? _anio;

  bool get _formCompleto => _marca != null && _modelo != null && _anio != null;

  // ===== Selector Bottom Sheet de Veloce Automotive System =====
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
                color: AppColors.loginSurface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusLg),
                ),
              ),
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.xl,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicador superior
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.loginOutlineVar,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.loginOnSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Buscador Premium
                  TextField(
                    onChanged: (val) {
                      setModalState(() {
                        filtro = val;
                      });
                    },
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.loginOnSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buscar...',
                      hintStyle: const TextStyle(
                        color: AppColors.loginOnSurfaceVar,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppColors.loginOnSurfaceVar,
                      ),
                      filled: true,
                      fillColor: AppColors.loginSurfaceHigh.withValues(alpha: 0.6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        borderSide: const BorderSide(
                          color: AppColors.loginOutlineVar,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        borderSide: const BorderSide(
                          color: AppColors.loginOutlineVar,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        borderSide: const BorderSide(
                          color: AppColors.loginPrimary,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: opcionesFiltradas.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                              child: Text(
                                'No se encontraron resultados',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.loginOnSurfaceVar,
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
                                  horizontal: AppSpacing.md,
                                ),
                                title: Text(
                                  etiqueta(op),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                                    color: activo ? AppColors.loginPrimary : AppColors.loginOnSurface,
                                  ),
                                ),
                                trailing: activo
                                    ? const Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.loginPrimary,
                                        size: 18,
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
    ref.read(registerVehiclesProvider.notifier).addUserCar(
          brand: _marca!,
          model: _modelo!,
          year: _anio!,
        );
    setState(() {
      _marca = null;
      _modelo = null;
      _anio = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehiculos = ref.watch(registerVehiclesProvider);
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.loginBg,
      appBar: isWideScreen
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  color: AppColors.loginOnSurfaceVar,
                  onPressed: () => context.go(RouteNames.registerUser),
                  tooltip: 'Volver al registro básico',
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: isWideScreen ? 0 : AppSpacing.xl2,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!isWideScreen) ...[
                          CircularBackButton(
                            onTap: () => context.go(RouteNames.registerUser),
                            tooltip: 'Volver al registro básico',
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],

                        // Cabecera
                        const Text(
                          'Mis Vehículos',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.loginOnSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'Agrega los vehículos que quieres gestionar. Puedes añadir más después.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.loginOnSurfaceVar,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl2),

                        // Formulario de Vehículo
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xl2),
                          decoration: BoxDecoration(
                            color: AppColors.loginSurface,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                            border: Border.all(
                              color: AppColors.loginOutlineVar,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 32,
                                offset: const Offset(0, 12),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _FieldLabel('MARCA'),
                              const SizedBox(height: AppSpacing.xs),
                              _SelectorField(
                                icon: Icons.directions_car_outlined,
                                value: _marca,
                                placeholder: 'Selecciona la marca',
                                onTap: () async {
                                  final r = await _abrirSelector<String>(
                                    titulo: 'Selecciona la marca',
                                    opciones: _catalogo.keys.toList(),
                                    etiqueta: (m) => m,
                                    seleccionado: _marca,
                                  );
                                  if (r != null) {
                                    setState(() {
                                      _marca = r;
                                      _modelo = null;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),

                              const _FieldLabel('MODELO'),
                              const SizedBox(height: AppSpacing.xs),
                              _SelectorField(
                                icon: Icons.commute_outlined,
                                value: _modelo,
                                placeholder: _marca == null
                                    ? 'Primero elige una marca'
                                    : 'Selecciona el modelo',
                                enabled: _marca != null,
                                onTap: () async {
                                  final r = await _abrirSelector<String>(
                                    titulo: 'Modelos de $_marca',
                                    opciones: _catalogo[_marca]!,
                                    etiqueta: (m) => m,
                                    seleccionado: _modelo,
                                  );
                                  if (r != null) setState(() => _modelo = r);
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),

                              const _FieldLabel('AÑO'),
                              const SizedBox(height: AppSpacing.xs),
                              _SelectorField(
                                icon: Icons.calendar_today_outlined,
                                value: _anio?.toString(),
                                placeholder: 'Selecciona el año',
                                onTap: () async {
                                  final r = await _abrirSelector<int>(
                                    titulo: 'Selecciona el año',
                                    opciones: _anios,
                                    etiqueta: (a) => '$a',
                                    seleccionado: _anio,
                                  );
                                  if (r != null) setState(() => _anio = r);
                                },
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              // Botón agregar vehículo
                              SizedBox(
                                height: AppSpacing.buttonHeightMd,
                                child: OutlinedButton.icon(
                                  onPressed: _formCompleto ? _agregarVehiculo : null,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text(
                                    'AGREGAR VEHÍCULO',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.loginPrimary,
                                    disabledForegroundColor: AppColors.loginOnSurfaceVar.withValues(alpha: 0.5),
                                    side: BorderSide(
                                      color: _formCompleto
                                          ? AppColors.loginPrimary
                                          : AppColors.loginOutlineVar,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl2),

                        // Lista de vehículos agregados
                        if (vehiculos.isEmpty)
                          const _EmptyUserCarsCard()
                        else ...[
                          Row(
                            children: [
                              const _FieldLabel('TUS VEHÍCULOS'),
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.loginPrimary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${vehiculos.length}',
                                  style: const TextStyle(
                                    color: AppColors.loginPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
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
                        ],
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Footer fijo: Continuar
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              color: AppColors.loginBg,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: SizedBox(
                    width: double.infinity,
                    height: AppSpacing.buttonHeightMd,
                    child: ElevatedButton(
                      onPressed: vehiculos.isEmpty
                          ? null
                          : () {
                              // Navegación final al home
                              context.go(RouteNames.home);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.loginPrimary,
                        disabledBackgroundColor: AppColors.loginOutlineVar,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: AppColors.loginOnSurfaceVar.withValues(alpha: 0.5),
                        elevation: vehiculos.isEmpty ? 0 : 3,
                        shadowColor: const Color(0x4DFF5C00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'CONTINUAR',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
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

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.loginOnSurfaceVar,
        letterSpacing: 0.8,
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
    final radius = BorderRadius.circular(AppSpacing.radiusSm);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: radius,
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: enabled 
                ? AppColors.loginSurface 
                : AppColors.loginSurfaceHigh.withValues(alpha: 0.5),
            border: Border.all(
              color: AppColors.loginOutlineVar,
            ),
            borderRadius: radius,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: AppColors.loginOnSurfaceVar,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  value ?? placeholder,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: value != null ? FontWeight.w600 : FontWeight.w400,
                    color: value != null 
                        ? AppColors.loginOnSurface 
                        : AppColors.loginOnSurfaceVar.withValues(alpha: 0.8),
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.loginOnSurfaceVar.withValues(alpha: 0.7),
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
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.loginSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: AppColors.loginOutlineVar,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.loginPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: AppColors.loginPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$brand $model',
                  style: const TextStyle(
                     fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.loginOnSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Año $year',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.loginOnSurfaceVar,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.loginError,
              size: 20,
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl2),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.loginOutlineVar,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.no_crash_outlined,
            size: 36,
            color: AppColors.loginOutlineVar,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Aún no has agregado vehículos',
            style: TextStyle(
              color: AppColors.loginOnSurfaceVar,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
