import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/services/location_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../vehicles/domain/entities/user_car.dart';
import '../../../../vehicles/presentation/providers/vehicle_providers.dart';
import '../../../../vehicles/presentation/widgets/garage_vehicle_selector_sheet.dart';
import '../../providers/home_providers.dart';

class HomeHeaderExpanded extends ConsumerStatefulWidget {
  /// Contenido opcional integrado dentro del bloque de color
  /// (ej. carrusel de publicidad, estilo Pedidos Ya).
  final Widget? child;

  /// Muestra el punto indicador sobre la campana de notificaciones.
  final bool hasUnreadNotifications;

  /// Acción al tocar la campana de notificaciones.
  final VoidCallback? onNotificationsTap;

  const HomeHeaderExpanded({
    super.key,
    this.child,
    this.hasUnreadNotifications = false,
    this.onNotificationsTap,
  });

  @override
  ConsumerState<HomeHeaderExpanded> createState() => _HomeHeaderExpandedState();
}

class _HomeHeaderExpandedState extends ConsumerState<HomeHeaderExpanded> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialLocationPermission();
    });
  }

  Future<void> _checkInitialLocationPermission() async {
    final service = ref.read(locationServiceProvider);
    final permission = await service.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      final isServiceEnabled = await service.isLocationServiceEnabled();
      if (isServiceEnabled) {
        ref.read(isLocationSharedProvider.notifier).state = true;
        await ref.read(userLocationProvider.notifier).updateLocation();
      }
    }
  }

  Future<void> _handleLocationToggle(BuildContext context) async {
    final isCurrentlyShared = ref.read(isLocationSharedProvider);
    if (isCurrentlyShared) {
      ref.read(isLocationSharedProvider.notifier).state = false;
      return;
    }

    final service = ref.read(locationServiceProvider);

    final isServiceEnabled = await service.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      if (!context.mounted) return;
      _showGpsDisabledDialog(context);
      return;
    }

    var permission = await service.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await service.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permiso de ubicación denegado por el usuario.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!context.mounted) return;
      _showSettingsRedirectDialog(context);
      return;
    }

    ref.read(isLocationSharedProvider.notifier).state = true;
    final success =
        await ref.read(userLocationProvider.notifier).updateLocation();
    if (!success) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No se pudo obtener la ubicación exacta. Usando última conocida.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _showGpsDisabledDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(Icons.location_off_rounded,
                color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'GPS Desactivado',
                style: GoogleFonts.hankenGrotesk(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'El servicio de ubicación (GPS) está apagado en tu dispositivo. Puedes activarlo en tu configuración o continuar usando la última ubicación conocida.',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.hankenGrotesk(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final service = ref.read(locationServiceProvider);
                    final lastKnown = await service.getLastKnownPosition();
                    if (lastKnown != null) {
                      ref.read(isLocationSharedProvider.notifier).state = true;
                      ref.read(userLocationProvider.notifier).updateLocation();
                    } else {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'No hay ubicación conocida anterior. Activa el GPS.'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Usar última',
                    style: GoogleFonts.hankenGrotesk(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSettingsRedirectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(Icons.settings_applications_rounded,
                color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Permiso de Ubicación',
                style: GoogleFonts.hankenGrotesk(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Para buscar talleres o repuestos cercanos a ti, la aplicación necesita acceder a tu ubicación. Por favor, actívala en los Ajustes del sistema.',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.hankenGrotesk(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ref.read(locationServiceProvider).openAppSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Ir a Ajustes',
                    style: GoogleFonts.hankenGrotesk(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleVehicleSelection(
    BuildContext context,
    UserCar? selectedVehicle,
  ) async {
    final result = await GarageVehicleSelectorSheet.show(
      context,
      selectedCar: selectedVehicle,
    );
    if (!mounted || result == null) return;

    ref.read(searchVehicleProvider.notifier).state = result.car;
    ref.read(searchVehicleVariantIdProvider.notifier).state = result.variantId;
  }

  @override
  Widget build(BuildContext context) {
    final isLocationShared = ref.watch(isLocationSharedProvider);
    final userName = ref.watch(authProvider).user?.name.trim();
    final selectedSearchVehicle = ref.watch(searchVehicleProvider);
    final garageCars = ref.watch(userCarsProvider).valueOrNull;
    final fallbackVehicle =
        garageCars == null || garageCars.isEmpty ? null : garageCars.first;
    final selectedVehicle = selectedSearchVehicle ?? fallbackVehicle;

    final statusBarHeight = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          top: statusBarHeight + AppSpacing.sm,
          bottom: AppSpacing.xl,
        ),
        decoration: const BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(28),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fila superior: ubicación + notificaciones ────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  // Ubicación (tappable para compartir/dejar de compartir)
                  Expanded(
                    child: Semantics(
                      button: true,
                      excludeSemantics: true,
                      label: isLocationShared
                          ? 'Desactivar ubicación'
                          : 'Activar ubicación',
                      child: SizedBox(
                        key: const Key('home-location-control'),
                        height: AppSpacing.xl5,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _handleLocationToggle(context),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            child: Row(
                              children: [
                                Icon(
                                  isLocationShared
                                      ? Icons.location_on
                                      : Icons.location_on_outlined,
                                  color: AppColors.textOnPrimary,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Flexible(
                                  child: Text(
                                    isLocationShared
                                        ? 'Ubicación activada'
                                        : 'Ubicación desactivada',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textOnPrimary,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (widget.onNotificationsTap != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _NotificationButton(
                      hasUnread: widget.hasUnreadNotifications,
                      onTap: widget.onNotificationsTap!,
                    ),
                  ],
                ],
              ),
            ),

            // ── Saludo personalizado ───────────────────────────────────
            if (userName != null && userName.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  'Hola, $userName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textOnPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Semantics(
                button: true,
                excludeSemantics: true,
                label: selectedVehicle == null
                    ? 'Seleccionar vehículo'
                    : 'Vehículo seleccionado: ${selectedVehicle.brand} ${selectedVehicle.model}. Toca para cambiar.',
                child: SizedBox(
                  width: double.infinity,
                  height: AppSpacing.xl5,
                  child: Material(
                    color: Colors.transparent,
                    child: Ink(
                      decoration: BoxDecoration(
                        color: AppColors.textOnPrimary.withValues(alpha: 0.06),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(
                          color:
                              AppColors.textOnPrimary.withValues(alpha: 0.45),
                        ),
                      ),
                      child: InkWell(
                        onTap: () =>
                            _handleVehicleSelection(context, selectedVehicle),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.directions_car_outlined,
                                color: AppColors.textOnPrimary,
                                size: 22,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  selectedVehicle == null
                                      ? 'Seleccionar vehículo'
                                      : '${selectedVehicle.brand} ${selectedVehicle.model}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textOnPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textOnPrimary,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Publicidad integrada dentro del bloque de color ────────────
            if (widget.child != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: widget.child!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Botón de notificaciones del header, con punto indicador de no leídas.
class _NotificationButton extends StatelessWidget {
  final bool hasUnread;
  final VoidCallback onTap;

  const _NotificationButton({
    required this.hasUnread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: hasUnread
          ? 'Notificaciones, tienes notificaciones sin leer'
          : 'Notificaciones',
      child: SizedBox.square(
        dimension: AppSpacing.xl5,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textOnPrimary,
                  size: 24,
                ),
                if (hasUnread)
                  Positioned(
                    right: 10,
                    top: 9,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.textOnPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryDark,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
