import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para exponer el servicio de ubicación.
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Indica si el usuario tiene la búsqueda por ubicación activa.
final isLocationSharedProvider = StateProvider<bool>((ref) {
  return false;
});

/// Servicio encargado de la interacción directa con el plugin de geolocalización.
class LocationService {
  /// Verifica si el GPS/servicio de ubicación está encendido.
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Comprueba el estado del permiso de ubicación.
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Solicita el permiso de ubicación al usuario.
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Obtiene la posición actual con un límite de tiempo de 7 segundos.
  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 7),
    );
  }

  /// Convierte coordenadas en una etiqueta breve y legible para el header.
  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks =
          await Geocoding().placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return null;

      final place = placemarks.first;
      final parts = <String>[
        place.street ?? '',
        place.subLocality ?? '',
        place.locality ?? '',
        place.administrativeArea ?? '',
      ].map((part) => part.trim()).where((part) => part.isNotEmpty).toList();

      final uniqueParts = <String>[];
      for (final part in parts) {
        if (!uniqueParts.any(
          (existing) => existing.toLowerCase() == part.toLowerCase(),
        )) {
          uniqueParts.add(part);
        }
        if (uniqueParts.length == 2) break;
      }

      return uniqueParts.isEmpty ? null : uniqueParts.join(', ');
    } catch (_) {
      return null;
    }
  }

  /// Abre la configuración de la aplicación en el dispositivo del usuario.
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}

/// Notificador de estado para la posición del usuario.
class UserLocationNotifier extends StateNotifier<AsyncValue<Position?>> {
  final LocationService _locationService;

  UserLocationNotifier(this._locationService)
      : super(const AsyncValue.data(null));

  /// Intenta actualizar la ubicación del usuario.
  /// Retorna un boolean que indica si se logró obtener una posición (actual o fallback).
  Future<bool> updateLocation() async {
    state = const AsyncValue.loading();
    try {
      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = const AsyncValue.error(
            'Servicio de ubicación desactivado', StackTrace.empty);
        return false;
      }

      var permission = await _locationService.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _locationService.requestPermission();
        if (permission == LocationPermission.denied) {
          state = const AsyncValue.error(
              'Permiso de ubicación denegado', StackTrace.empty);
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = const AsyncValue.error(
            'Permisos de ubicación denegados permanentemente',
            StackTrace.empty);
        return false;
      }

      final position = await _locationService.getCurrentPosition();
      state = AsyncValue.data(position);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// Limpia la ubicación guardada.
  void clear() {
    state = const AsyncValue.data(null);
  }
}

/// Provider global que expone la ubicación activa del usuario.
final userLocationProvider =
    StateNotifierProvider<UserLocationNotifier, AsyncValue<Position?>>((ref) {
  final service = ref.watch(locationServiceProvider);
  return UserLocationNotifier(service);
});
