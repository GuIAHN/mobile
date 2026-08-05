import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/home_providers.dart';

class HomeHeader extends ConsumerStatefulWidget {
  const HomeHeader({super.key});

  @override
  ConsumerState<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends ConsumerState<HomeHeader> {
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

    // 1. Verificar si el GPS está habilitado
    final isServiceEnabled = await service.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      if (!context.mounted) return;
      _showGpsDisabledDialog(context);
      return;
    }

    // 2. Verificar y solicitar permisos
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

    // 3. Activar compartir ubicación
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

  @override
  Widget build(BuildContext context) {
    final isLocationShared = ref.watch(isLocationSharedProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          // Logo + Nombre de la App "GUIA HN" con toques naranja (Todo Mayúsculas)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo_icon.png',
                height: 72,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(width: 10),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  children: [
                    const TextSpan(text: 'GU'),
                    TextSpan(
                      text: 'IA',
                      style: TextStyle(
                        color: AppColors.primary,
                        shadows: [
                          Shadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'HN',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Toggle de Compartir Ubicación
          GestureDetector(
            onTap: () => _handleLocationToggle(context),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isLocationShared ? AppColors.primaryMuted : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isLocationShared ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isLocationShared
                    ? Icons.location_on
                    : Icons.location_on_outlined,
                color: isLocationShared
                    ? AppColors.primary
                    : AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
