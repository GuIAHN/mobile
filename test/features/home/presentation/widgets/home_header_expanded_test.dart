import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guiautomotriz_mobile/core/services/location_service.dart';
import 'package:guiautomotriz_mobile/core/storage/secure_storage.dart';
import 'package:guiautomotriz_mobile/core/theme/app_colors.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/user_role.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/entities/user.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/register_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/upload_avatar_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/providers/auth_state.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/header/home_header_expanded.dart';
import 'package:guiautomotriz_mobile/features/vehicles/domain/entities/user_car.dart';
import 'package:guiautomotriz_mobile/features/vehicles/presentation/providers/vehicle_providers.dart';
import 'package:mocktail/mocktail.dart';

class _FakeLocationService extends LocationService {
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.denied;
}

class _EnabledLocationService extends LocationService {
  double? lastAddressLatitude;
  double? lastAddressLongitude;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<Position> getCurrentPosition() async => Position(
        longitude: -66.9036,
        latitude: 10.4806,
        timestamp: DateTime(2026),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

  @override
  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    lastAddressLatitude = latitude;
    lastAddressLongitude = longitude;
    return 'Sabana Grande, Caracas';
  }
}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSecureStorage extends Mock implements SecureStorage {}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(AuthState initialState)
      : super(
          loginUseCase: LoginUseCase(_MockAuthRepository()),
          registerUseCase: RegisterUseCase(_MockAuthRepository()),
          updateProfileUseCase: UpdateProfileUseCase(_MockAuthRepository()),
          uploadAvatarUseCase: UploadAvatarUseCase(_MockAuthRepository()),
          authRepository: _MockAuthRepository(),
          secureStorage: _MockSecureStorage(),
        ) {
    state = initialState;
  }

  @override
  Future<void> checkAuthStatus() async {}
}

void main() {
  const audi = UserCar(
    id: 'car-1',
    brand: 'Audi',
    model: '4000',
    year: 1985,
  );
  const toyota = UserCar(
    id: 'car-2',
    brand: 'Toyota',
    model: 'Corolla',
    year: 2020,
  );
  const user = User(
    id: 'user-1',
    email: 'elio@example.com',
    name: 'Elio',
  );

  ProviderContainer containerWithGarage(
    Future<List<UserCar>> Function(Ref ref) loadCars,
  ) {
    return ProviderContainer(
      overrides: [
        authProvider.overrideWith(
          (ref) => _TestAuthNotifier(
            const AuthState(status: AuthStatus.authenticated, user: user),
          ),
        ),
        userCarsProvider.overrideWith(loadCars),
        locationServiceProvider.overrideWithValue(_FakeLocationService()),
      ],
    );
  }

  ProviderContainer containerWithCars(List<UserCar> cars) =>
      containerWithGarage((ref) async => cars);

  Future<void> pumpHeader(
    WidgetTester tester,
    ProviderContainer container, {
    VoidCallback? onNotificationsTap,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: HomeHeaderExpanded(
              onNotificationsTap: onNotificationsTap,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows the accessible vehicle-aware orange header',
      (tester) async {
    final container = containerWithCars([audi]);
    addTearDown(container.dispose);

    await pumpHeader(tester, container);

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).color == AppColors.primary,
      ),
      findsOneWidget,
    );
    expect(find.text('Hola, Elio'), findsOneWidget);
    final vehicleControl =
        find.byKey(const Key('home-selected-vehicle-control'));
    expect(vehicleControl, findsOneWidget);
    expect(find.text('Audi 4000 · 1985'), findsOneWidget);
    expect(find.text('¿En qué podemos ayudarte hoy?'), findsNothing);
    expect(
      tester.getSize(vehicleControl).height,
      greaterThanOrEqualTo(48),
    );
    expect(find.text('Ubicación desactivada'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_outlined), findsNothing);

    final locationTarget = find.byKey(const Key('home-location-control'));
    expect(locationTarget, findsOneWidget);
    expect(tester.getSize(locationTarget).height, greaterThanOrEqualTo(48));
    expect(find.bySemanticsLabel('Activar ubicación'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Vehículo seleccionado: Audi 4000, 1985'),
      findsOneWidget,
    );
  }, semanticsEnabled: true);

  testWidgets('uses the blue and black header car asset', (tester) async {
    final container = containerWithCars([audi]);
    addTearDown(container.dispose);

    await pumpHeader(tester, container);

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/header_car_blue_black.png',
      ),
      findsOneWidget,
    );
  });

  testWidgets('keeps the temporary location action at least 48dp high',
      (tester) async {
    final container = containerWithCars(const []);
    addTearDown(container.dispose);

    await pumpHeader(tester, container);

    final locationControl = find.byKey(const Key('home-location-control'));
    expect(locationControl, findsOneWidget);
    expect(tester.getSize(locationControl).height, greaterThanOrEqualTo(48));
  });

  testWidgets('omits the user role suffix from the greeting', (tester) async {
    const store = User(
      id: 'store-1',
      email: 'store@example.com',
      name: 'Multirepuestos El Pana (Tienda)',
      role: UserRole.store,
    );
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(
          (ref) => _TestAuthNotifier(
            const AuthState(
              status: AuthStatus.authenticated,
              user: store,
            ),
          ),
        ),
        userCarsProvider.overrideWith((ref) async => const <UserCar>[]),
        locationServiceProvider.overrideWithValue(_FakeLocationService()),
      ],
    );
    addTearDown(container.dispose);

    await pumpHeader(tester, container);

    expect(find.text('Hola, Multirepuestos El Pana'), findsOneWidget);
    expect(find.textContaining('(Tienda)'), findsNothing);
    expect(find.byKey(const Key('home-location-control')), findsNothing);
    expect(find.bySemanticsLabel('Activar ubicación'), findsNothing);
  });

  testWidgets('workshop cannot activate a temporary location', (tester) async {
    const workshop = User(
      id: 'workshop-1',
      email: 'workshop@example.com',
      name: 'Taller Norte',
      role: UserRole.workshop,
      latitude: 10.4806,
      longitude: -66.9036,
    );
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(
          (ref) => _TestAuthNotifier(
            const AuthState(
              status: AuthStatus.authenticated,
              user: workshop,
            ),
          ),
        ),
        userCarsProvider.overrideWith((ref) async => const <UserCar>[]),
        locationServiceProvider.overrideWithValue(_EnabledLocationService()),
        isLocationSharedProvider.overrideWith((ref) => true),
      ],
    );
    addTearDown(container.dispose);

    await pumpHeader(tester, container);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-location-control')), findsNothing);
    expect(find.bySemanticsLabel('Activar ubicación'), findsNothing);
    expect(container.read(isLocationSharedProvider), isFalse);
    expect(container.read(userLocationProvider).valueOrNull, isNull);
  }, semanticsEnabled: true);

  testWidgets('shows honest empty-garage and location states', (tester) async {
    final container = containerWithCars([]);
    addTearDown(container.dispose);

    await pumpHeader(tester, container);

    expect(
      find.byKey(const Key('home-selected-vehicle-control')),
      findsOneWidget,
    );
    expect(find.text('Seleccionar vehículo'), findsOneWidget);
    expect(find.text('Ubicación desactivada'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Seleccionar vehículo'),
      findsOneWidget,
    );
  });

  testWidgets('shows the current resolved location name', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(
          (ref) => _TestAuthNotifier(
            const AuthState(status: AuthStatus.authenticated, user: user),
          ),
        ),
        userCarsProvider.overrideWith((ref) async => const [audi]),
        locationServiceProvider.overrideWithValue(_EnabledLocationService()),
        isLocationSharedProvider.overrideWith((ref) => true),
      ],
    );
    addTearDown(container.dispose);

    await pumpHeader(tester, container);
    await tester.pumpAndSettle();

    expect(find.text('Sabana Grande, Caracas'), findsOneWidget);
    expect(find.text('Ubicación activada'), findsNothing);
  });

  testWidgets('activation stores and labels the same search position',
      (tester) async {
    final service = _EnabledLocationService();
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(
          (ref) => _TestAuthNotifier(
            const AuthState(status: AuthStatus.authenticated, user: user),
          ),
        ),
        userCarsProvider.overrideWith((ref) async => const [audi]),
        locationServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    await pumpHeader(tester, container);
    await tester.tap(find.byKey(const Key('home-location-control')));
    await tester.pumpAndSettle();

    final position = container.read(userLocationProvider).valueOrNull;
    expect(position?.latitude, 10.4806);
    expect(position?.longitude, -66.9036);
    expect(container.read(isLocationSharedProvider), isTrue);
    expect(find.text('Sabana Grande, Caracas'), findsOneWidget);
    expect(service.lastAddressLatitude, position?.latitude);
    expect(service.lastAddressLongitude, position?.longitude);
  });

  testWidgets('deactivation clears the active search position', (tester) async {
    final service = _EnabledLocationService();
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(
          (ref) => _TestAuthNotifier(
            const AuthState(status: AuthStatus.authenticated, user: user),
          ),
        ),
        userCarsProvider.overrideWith((ref) async => const [audi]),
        locationServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    await pumpHeader(tester, container);
    await tester.tap(find.byKey(const Key('home-location-control')));
    await tester.pumpAndSettle();
    expect(container.read(userLocationProvider).valueOrNull, isNotNull);

    await tester.tap(find.byKey(const Key('home-location-control')));
    await tester.pumpAndSettle();

    expect(container.read(isLocationSharedProvider), isFalse);
    expect(container.read(userLocationProvider).valueOrNull, isNull);
  });

  testWidgets('shows an honest garage loading state', (tester) async {
    final pendingCars = Completer<List<UserCar>>();
    final container = containerWithGarage((ref) => pendingCars.future);
    addTearDown(container.dispose);

    await pumpHeader(tester, container);

    expect(
      find.byKey(const Key('home-selected-vehicle-control')),
      findsOneWidget,
    );
    expect(find.text('Cargando vehículo…'), findsOneWidget);
    expect(find.text('Seleccionar vehículo'), findsNothing);
    expect(
      find.bySemanticsLabel('Cargando vehículo'),
      findsOneWidget,
    );
  }, semanticsEnabled: true);

  testWidgets('shows an honest garage error state', (tester) async {
    final container = containerWithGarage(
      (ref) async => throw StateError('private backend detail'),
    );
    addTearDown(container.dispose);

    await pumpHeader(tester, container);

    expect(
      find.byKey(const Key('home-selected-vehicle-control')),
      findsOneWidget,
    );
    expect(find.text('No pudimos cargar tu vehículo'), findsOneWidget);
    expect(find.text('Seleccionar vehículo'), findsNothing);
    expect(find.textContaining('private backend detail'), findsNothing);
    expect(
      find.bySemanticsLabel(
        'No pudimos cargar tu vehículo. Toca para intentarlo de nuevo',
      ),
      findsOneWidget,
    );
  }, semanticsEnabled: true);

  testWidgets('updates the shared search vehicle after garage selection',
      (tester) async {
    final container = containerWithCars([audi, toyota]);
    addTearDown(container.dispose);

    await pumpHeader(tester, container);
    await tester.tap(find.byKey(const Key('home-selected-vehicle-control')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Toyota Corolla').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(container.read(searchVehicleProvider), toyota);
    expect(container.read(searchVehicleVariantIdProvider), isNull);
    expect(find.text('Toyota Corolla · 2020'), findsOneWidget);
  });

  testWidgets('fits small and large phones with scaled text and 48 dp actions',
      (tester) async {
    final container = containerWithCars([audi]);
    addTearDown(container.dispose);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final size in const [Size(320, 700), Size(430, 932)]) {
      tester.view.physicalSize = size;
      await pumpHeader(
        tester,
        container,
        onNotificationsTap: () {},
        textScale: 2,
      );

      final vehicleControl =
          find.byKey(const Key('home-selected-vehicle-control'));
      expect(vehicleControl, findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(vehicleControl).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.bySemanticsLabel('Notificaciones')),
        const Size(48, 48),
      );
    }
  }, semanticsEnabled: true);
}
