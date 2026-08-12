import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guiautomotriz_mobile/core/services/location_service.dart';
import 'package:guiautomotriz_mobile/core/storage/secure_storage.dart';
import 'package:guiautomotriz_mobile/core/theme/app_colors.dart';
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
            (widget.decoration! as BoxDecoration).color ==
                AppColors.primaryDark,
      ),
      findsOneWidget,
    );
    expect(find.text('Hola, Elio'), findsOneWidget);
    expect(find.text('Audi 4000'), findsOneWidget);
    expect(find.text('Ubicación desactivada'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_outlined), findsNothing);

    final locationTarget = find.byKey(const Key('home-location-control'));
    expect(locationTarget, findsOneWidget);
    expect(tester.getSize(locationTarget).height, greaterThanOrEqualTo(48));
    expect(find.bySemanticsLabel('Activar ubicación'), findsOneWidget);
    expect(
      tester
          .getSize(find.bySemanticsLabel(RegExp('Vehículo seleccionado')))
          .height,
      greaterThanOrEqualTo(48),
    );
  }, semanticsEnabled: true);

  testWidgets('shows honest empty-garage and location states', (tester) async {
    final container = containerWithCars([]);
    addTearDown(container.dispose);

    await pumpHeader(tester, container);

    expect(find.text('Seleccionar vehículo'), findsOneWidget);
    expect(find.text('Ubicación desactivada'), findsOneWidget);
  });

  testWidgets('shows an honest garage loading state', (tester) async {
    final pendingCars = Completer<List<UserCar>>();
    final container = containerWithGarage((ref) => pendingCars.future);
    addTearDown(container.dispose);

    await pumpHeader(tester, container);

    expect(find.text('Cargando vehículo…'), findsOneWidget);
    expect(find.text('Seleccionar vehículo'), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp('Cargando vehículo')),
      findsOneWidget,
    );
  }, semanticsEnabled: true);

  testWidgets('shows an honest garage error state', (tester) async {
    final container = containerWithGarage(
      (ref) async => throw StateError('private backend detail'),
    );
    addTearDown(container.dispose);

    await pumpHeader(tester, container);

    expect(find.text('No pudimos cargar tu vehículo'), findsOneWidget);
    expect(find.text('Seleccionar vehículo'), findsNothing);
    expect(find.textContaining('private backend detail'), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp('No pudimos cargar tu vehículo')),
      findsOneWidget,
    );
  }, semanticsEnabled: true);

  testWidgets('updates the shared search vehicle after garage selection',
      (tester) async {
    final container = containerWithCars([audi, toyota]);
    addTearDown(container.dispose);

    await pumpHeader(tester, container);
    await tester.tap(find.text('Audi 4000'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Toyota Corolla').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(container.read(searchVehicleProvider), toyota);
    expect(container.read(searchVehicleVariantIdProvider), isNull);
    expect(find.text('Toyota Corolla'), findsOneWidget);
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

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.bySemanticsLabel('Notificaciones')),
        const Size(48, 48),
      );
      final locationParagraph = tester.renderObject<RenderParagraph>(
        find.text('Ubicación desactivada'),
      );
      expect(locationParagraph.didExceedMaxLines, isFalse);
    }
  }, semanticsEnabled: true);
}
