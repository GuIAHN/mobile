import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/auth_state.dart';
import '../../features/auth/presentation/providers/social_registration_state.dart';
import '../../features/chat/presentation/providers/chat_providers.dart';
import '../../features/home/presentation/providers/home_providers.dart';
import '../../features/home/domain/entities/home_filters.dart';
import '../../features/reports/presentation/providers/reports_provider.dart';
import '../../features/vehicles/presentation/providers/register_vehicles_provider.dart';
import '../notifications/notification_provider.dart';
import '../services/location_service.dart';
import '../services/socket_service.dart';
import 'session_generation_provider.dart';

typedef _SessionIdentity = ({String? userId, AuthStatus status});

/// Mantiene una frontera estricta entre sesiones dentro del mismo proceso.
///
/// El `ProviderScope` vive durante toda la ejecución de la app, por lo que un
/// logout no destruye por sí solo los providers no-autoDispose. Este
/// coordinador observa la identidad, limpia el estado privado cuando cambia y
/// abre el socket únicamente después de que la nueva sesión está autenticada.
final sessionStateCoordinatorProvider = Provider<void>((ref) {
  ref.listen<_SessionIdentity>(
    authProvider.select(
      (state) => (userId: state.user?.id, status: state.status),
    ),
    (previous, next) {
      final socket = ref.read(socketServiceProvider);
      final identityChanged = previous?.userId != next.userId;

      if (identityChanged) {
        socket.disconnect();
        ref.read(sessionGenerationProvider.notifier).state += 1;
        resetSessionScopedState(ref);
      }

      if (next.status == AuthStatus.authenticated && next.userId != null) {
        // Dejar que la escritura del nuevo JWT termine antes de leerlo desde
        // SecureStorage y crear el transporte de la cuenta entrante.
        scheduleMicrotask(() => unawaited(socket.connect()));
      } else {
        socket.disconnect();
      }
    },
  );
});

/// Reinicia datos, borradores y preferencias que no deben cruzar cuentas.
/// Se mantiene como función pública para poder probar la frontera sin red.
void resetSessionScopedState(Ref ref) {
  // Los datos remotos observan la generación de sesión y se reconstruyen sólo
  // si estaban activos. Aquí se reinicia únicamente estado local ligero para
  // no disparar consultas durante el logout.
  ref.read(notificationProvider.notifier).dismissAll();

  ref.read(storeStatusFilterProvider.notifier).state = 'PENDING';
  ref.read(consumerStatusFilterProvider.notifier).state = 'OPEN';
  ref.read(homeTabProvider.notifier).state = MainNavigationTab.home;
  ref.read(homeFiltersProvider.notifier).state = const HomeFilters();
  ref.read(searchQueryProvider.notifier).state = '';
  ref.read(searchVehicleProvider.notifier).state = null;
  ref.read(searchVehicleModelIdProvider.notifier).state = null;
  ref.read(searchRequestNotifierProvider.notifier).reset();

  ref.read(isLocationSharedProvider.notifier).state = false;
  ref.read(userLocationProvider.notifier).clear();

  ref.invalidate(dashboardFilterProvider);
  ref.read(registerVehiclesProvider.notifier).clear();
  ref.read(socialRegistrationProvider.notifier).clear();
}
