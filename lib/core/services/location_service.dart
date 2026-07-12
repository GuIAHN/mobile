import 'package:geolocator/geolocator.dart';
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

  /// Obtiene la última ubicación conocida del dispositivo.
  Future<Position?> getLastKnownPosition() async {
    return await Geolocator.getLastKnownPosition();
  }

  /// Abre la configuración de la aplicación en el dispositivo del usuario.
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}

/// Notificador de estado para la posición del usuario.
class UserLocationNotifier extends StateNotifier<AsyncValue<Position?>> {
  final LocationService _locationService;
  final Ref _ref;

  UserLocationNotifier(this._locationService, this._ref)
      : super(const AsyncValue.data(null));

  /// Intenta actualizar la ubicación del usuario.
  /// Retorna un boolean que indica si se logró obtener una posición (actual o fallback).
  Future<bool> updateLocation() async {
    state = const AsyncValue.loading();
    // TEST ONLY: Hardcoded coordinates
    final mockPosition = Position(
      longitude: -66.857611,
      latitude: 10.543833,
      timestamp: DateTime.now(),
      accuracy: 100.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
    state = AsyncValue.data(mockPosition);
    return true;
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
  return UserLocationNotifier(service, ref);
});
