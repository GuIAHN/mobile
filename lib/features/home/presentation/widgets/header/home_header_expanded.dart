import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/services/location_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/skeleton_loader.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../auth/presentation/providers/auth_state.dart';

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
  String? _resolvedLocationName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialLocationPermission();
    });
  }

  Future<void> _checkInitialLocationPermission() async {
    final isShared = ref.read(isLocationSharedProvider);
    if (!isShared) return;

    final storedPosition = ref.read(userLocationProvider).valueOrNull;
    if (storedPosition != null) {
      await _resolveLocationName(storedPosition);
      return;
    }

    final service = ref.read(locationServiceProvider);
    final permission = await service.checkPermission();

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      final success =
          await ref.read(userLocationProvider.notifier).updateLocation();
      if (!mounted) return;
      final position = ref.read(userLocationProvider).valueOrNull;
      if (success && position != null) {
        await _resolveLocationName(position);
      } else {
        ref.read(isLocationSharedProvider.notifier).state = false;
      }
    } else {
      ref.read(isLocationSharedProvider.notifier).state = false;
      ref.read(userLocationProvider.notifier).clear();
    }
  }

  Future<void> _resolveLocationName(Position position) async {
    try {
      final service = ref.read(locationServiceProvider);
      final placeName = await service.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;
      setState(() => _resolvedLocationName = placeName);
    } catch (_) {
      if (!mounted) return;
      setState(() => _resolvedLocationName = null);
    }
  }

  Future<void> _handleLocationToggle(BuildContext context) async {
    final service = ref.read(locationServiceProvider);
    final isShared = ref.read(isLocationSharedProvider);

    if (isShared) {
      ref.read(isLocationSharedProvider.notifier).state = false;
      ref.read(userLocationProvider.notifier).clear();
      setState(() => _resolvedLocationName = null);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ubicación desactivada'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } else {
      final success =
          await ref.read(userLocationProvider.notifier).updateLocation();
      if (!context.mounted) return;

      final position = ref.read(userLocationProvider).valueOrNull;
      if (success && position != null) {
        ref.read(isLocationSharedProvider.notifier).state = true;
        await _resolveLocationName(position);
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ubicación activada'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        ref.read(isLocationSharedProvider.notifier).state = false;
        final permission = await service.checkPermission();
        if (!context.mounted) return;
        if (permission == LocationPermission.deniedForever) {
          _showLocationSettingsDialog(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo obtener la ubicación'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    }
  }

  void _showLocationSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Permiso de ubicación permanente denegado',
          style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Para mostrarte mecánicos y talleres cercanos, necesitamos acceso a tu ubicación. '
          'Por favor, habilita el permiso en los ajustes de tu dispositivo.',
          style: GoogleFonts.hankenGrotesk(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: GoogleFonts.hankenGrotesk(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(locationServiceProvider).openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Ir a Ajustes',
              style: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLocationShared = ref.watch(isLocationSharedProvider);
    final locationAsync = ref.watch(userLocationProvider);
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name.trim();
    final isLoadingAuth = authState.status == AuthStatus.loading ||
        authState.status == AuthStatus.initial;

    final locationText = !isLocationShared
        ? 'Ubicación desactivada'
        : _resolvedLocationName ??
            (locationAsync.isLoading
                ? 'Obteniendo ubicación…'
                : 'Ubicación actual');

    final statusBarHeight = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(28),
          ),
        ),
        child: Stack(
          children: [
            // ── Formas orgánicas translúcidas de fondo (estilo mockup) ─────
            Positioned(
              top: -60,
              right: -50,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.13),
                ),
              ),
            ),
            Positioned(
              top: -110,
              right: -100,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -55,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.11),
                ),
              ),
            ),

            // ── Ilustración del vehículo en el lado derecho del header ───────
            Positioned(
              right: -30,
              bottom: -40,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/images/header_car_blue_black.png',
                  height: 180,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),

            // ── Contenido del Header ─────────────────────────────────────
            Padding(
              padding: EdgeInsets.only(
                top: statusBarHeight + AppSpacing.sm,
                bottom: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Fila superior: ubicación chip + notificaciones ───────────
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Semantics(
                            button: true,
                            excludeSemantics: true,
                            label: isLocationShared
                                ? 'Desactivar ubicación. Ubicación actual: $locationText'
                                : 'Activar ubicación',
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                key: const Key('home-location-control'),
                                onTap: () => _handleLocationToggle(context),
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusFull),
                                child: Container(
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusFull),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.35),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isLocationShared
                                            ? Icons.location_on_rounded
                                            : Icons.location_off_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          locationText,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.hankenGrotesk(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            letterSpacing: -0.1,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Colors.white,
                                        size: 16,
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

                  // ── Saludo + tagline ─────────────────────────────────────────
                  if (userName != null && userName.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 24,
                        right: 135,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, $userName',
                            maxLines: 2,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.4,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '¿En qué podemos ayudarte hoy?',
                            maxLines: 2,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.85),
                              letterSpacing: -0.1,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (isLoadingAuth) ...[
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 24,
                        right: 135,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(
                            width: 130,
                            height: 22,
                            borderRadius: 6,
                            baseColor: Colors.white.withValues(alpha: 0.22),
                            highlightColor: Colors.white.withValues(alpha: 0.40),
                          ),
                          const SizedBox(height: 8),
                          SkeletonBox(
                            width: 150,
                            height: 13,
                            borderRadius: 4,
                            baseColor: Colors.white.withValues(alpha: 0.16),
                            highlightColor: Colors.white.withValues(alpha: 0.30),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                  ],

                  // ── Publicidad integrada dentro del bloque de color ──────────
                  if (widget.child != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: widget.child!,
                    ),
                  ],
                ],
              ),
            ),
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
        dimension: 48,
        child: Material(
          color: Colors.white.withValues(alpha: 0.20),
          shape: CircleBorder(
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                if (hasUnread)
                  Positioned(
                    right: 9,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
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
