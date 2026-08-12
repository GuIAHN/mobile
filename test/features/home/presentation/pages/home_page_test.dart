import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/service_type.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/user_role.dart';
import 'package:guiautomotriz_mobile/core/router/route_names.dart';
import 'package:guiautomotriz_mobile/core/services/location_service.dart';
import 'package:guiautomotriz_mobile/core/storage/secure_storage.dart';
import 'package:guiautomotriz_mobile/features/ads/presentation/providers/ads_provider.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/entities/user.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/register_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/upload_avatar_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/providers/auth_state.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/home_item.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/promo.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/pages/home_page.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/providers/home_providers.dart';
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
  const consumer = User(
    id: 'consumer-1',
    email: 'elio@example.com',
    name: 'Elio',
    role: UserRole.consumer,
  );
  const car = UserCar(
    id: 'car-1',
    brand: 'Toyota',
    model: 'Corolla',
    year: 2022,
  );
  const promo = Promo(
    title: 'PROMOCIÓN QUE NO DEBE APARECER',
    subtitle: 'Oferta de prueba',
    iconName: 'local_offer_outlined',
    gradientColors: [0xFFF25C05, 0xFFBF4704],
  );

  HomeItem providerFixture(ServiceType type) => HomeItem(
        id: '${type.name}-1',
        name:
            type == ServiceType.workshops ? 'Taller Prueba' : 'Mecánico Prueba',
        detail: 'Diagnóstico automotriz',
        rating: 4.8,
        reviews: 24,
        distanceKm: 2.4,
        isOpen: true,
        iconName: 'engineering_outlined',
        type: type,
      );

  ProviderContainer containerFor({
    required AsyncValue<List<HomeItem>> workshops,
    required AsyncValue<List<HomeItem>> mechanics,
  }) {
    return ProviderContainer(
      overrides: [
        authProvider.overrideWith(
          (ref) => _TestAuthNotifier(
            const AuthState(
              status: AuthStatus.authenticated,
              user: consumer,
            ),
          ),
        ),
        userCarsProvider.overrideWith((ref) async => const [car]),
        locationServiceProvider.overrideWithValue(_FakeLocationService()),
        adsAsPromosProvider.overrideWith((ref, type) async => const [promo]),
        topProvidersProvider.overrideWith((ref, type) {
          return type == ServiceType.workshops ? workshops : mechanics;
        }),
        welcomeShownProvider.overrideWith((ref) => true),
      ],
    );
  }

  Widget subject(
    ProviderContainer container, {
    double width = 430,
    double height = 932,
    double textScale = 1,
    bool disableAnimations = false,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomePage()),
        GoRoute(
          path: RouteNames.workshops,
          builder: (_, __) => const Scaffold(body: Text('workshops-route')),
        ),
        GoRoute(
          path: RouteNames.mechanics,
          builder: (_, __) => const Scaffold(body: Text('mechanics-route')),
        ),
      ],
    );

    return UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          padding: const EdgeInsets.only(top: 24, bottom: 24),
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  Future<void> pumpHome(
    WidgetTester tester,
    ProviderContainer container, {
    double width = 430,
    double height = 932,
    double textScale = 1,
    bool disableAnimations = false,
  }) async {
    await tester.pumpWidget(
      subject(
        container,
        width: width,
        height: height,
        textScale: textScale,
        disableAnimations: disableAnimations,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Finder homeListView() => find.byWidgetPredicate(
        (widget) =>
            widget is ListView && widget.scrollDirection == Axis.vertical,
        description: 'Home vertical ListView',
      );

  testWidgets('consumer Home uses the approved content and visual order',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(430, 1800));
    final container = containerFor(
      workshops: AsyncValue.data([
        providerFixture(ServiceType.workshops),
      ]),
      mechanics: AsyncValue.data([
        providerFixture(ServiceType.mechanic),
      ]),
    );
    addTearDown(container.dispose);

    await pumpHome(tester, container, height: 1800);

    const orderedLabels = [
      '¿Qué necesitas hoy?',
      'Solicitar repuesto',
      'Talleres mejor valorados',
      'Mecánicos mejor valorados',
    ];
    final firstOccurrenceY = <double>[];
    for (final label in orderedLabels) {
      final finder = find.text(label);
      expect(finder, findsOneWidget);
      firstOccurrenceY.add(tester.getTopLeft(finder.first).dy);
    }
    expect(firstOccurrenceY, orderedEquals([...firstOccurrenceY]..sort()));

    expect(find.text('PROMOCIÓN QUE NO DEBE APARECER'), findsNothing);
    expect(find.text('Mi garage'), findsNothing);
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('Compras'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image == const AssetImage('assets/images/logo_icon.png'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('consumer Home renders both provider loading states',
      (tester) async {
    final container = containerFor(
      workshops: const AsyncValue.loading(),
      mechanics: const AsyncValue.loading(),
    );
    addTearDown(container.dispose);

    await pumpHome(tester, container);

    expect(find.byKey(const Key('top-provider-skeleton-1')), findsOneWidget);
    expect(find.text('Talleres mejor valorados'), findsOneWidget);
    await tester.fling(homeListView(), const Offset(0, -1600), 5000);
    await tester.pump();
    expect(find.byKey(const Key('top-provider-skeleton-1')), findsOneWidget);
    expect(find.text('Mecánicos mejor valorados'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('consumer Home renders both provider empty states',
      (tester) async {
    final container = containerFor(
      workshops: const AsyncValue.data([]),
      mechanics: const AsyncValue.data([]),
    );
    addTearDown(container.dispose);

    await pumpHome(tester, container);
    expect(find.text('Todavía no hay talleres valorados'), findsOneWidget);
    await tester.fling(homeListView(), const Offset(0, -1200), 5000);
    await tester.pump();

    expect(find.text('Todavía no hay mecánicos valorados'), findsOneWidget);
  });

  testWidgets('consumer Home renders safe provider errors without raw details',
      (tester) async {
    final container = containerFor(
      workshops: AsyncValue.error(
        Exception('private workshop database secret'),
        StackTrace.empty,
      ),
      mechanics: AsyncValue.error(
        Exception('private mechanic database secret'),
        StackTrace.empty,
      ),
    );
    addTearDown(container.dispose);

    await pumpHome(tester, container);
    expect(find.text('No pudimos cargar los talleres'), findsOneWidget);
    await tester.fling(homeListView(), const Offset(0, -1200), 5000);
    await tester.pump();

    expect(find.text('No pudimos cargar los mecánicos'), findsOneWidget);
    expect(find.textContaining('database secret'), findsNothing);
  });

  testWidgets('consumer Home renders both provider data states',
      (tester) async {
    final container = containerFor(
      workshops: AsyncValue.data([
        providerFixture(ServiceType.workshops),
      ]),
      mechanics: AsyncValue.data([
        providerFixture(ServiceType.mechanic),
      ]),
    );
    addTearDown(container.dispose);

    await pumpHome(tester, container);
    expect(find.text('Taller Prueba'), findsOneWidget);
    await tester.fling(homeListView(), const Offset(0, -1400), 5000);
    await tester.pump();

    expect(find.text('Mecánico Prueba'), findsOneWidget);
  });

  testWidgets('Home fits the approved phone and text-scale matrix',
      (tester) async {
    final previousOnError = FlutterError.onError;
    final errors = <FlutterErrorDetails>[];
    final missingContent = <String>[];
    FlutterError.onError = errors.add;
    addTearDown(() => tester.binding.setSurfaceSize(null));

    try {
      for (final width in const [375.0, 430.0]) {
        for (final textScale in const [1.0, 1.3, 2.0]) {
          final height = width == 375 ? 812.0 : 932.0;
          await tester.binding.setSurfaceSize(Size(width, height));
          final container = containerFor(
            workshops: AsyncValue.data([
              providerFixture(ServiceType.workshops),
            ]),
            mechanics: AsyncValue.data([
              providerFixture(ServiceType.mechanic),
            ]),
          );

          await pumpHome(
            tester,
            container,
            width: width,
            height: height,
            textScale: textScale,
          );
          await tester.fling(
            homeListView(),
            const Offset(0, -2400),
            6000,
          );
          await tester.pump();

          if (find.text('Mecánicos mejor valorados').evaluate().length != 1) {
            missingContent.add('$width/$textScale');
          }
          container.dispose();
        }
      }
    } finally {
      FlutterError.onError = previousOnError;
    }

    expect(missingContent, isEmpty);
    expect(
      errors,
      isEmpty,
      reason: errors.map((error) => error.exceptionAsString()).join('\n'),
    );
  });

  testWidgets('reduced motion disables the Home tab switch duration',
      (tester) async {
    final container = containerFor(
      workshops: const AsyncValue.data([]),
      mechanics: const AsyncValue.data([]),
    );
    addTearDown(container.dispose);

    await pumpHome(tester, container, disableAnimations: true);

    expect(
      tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
      Duration.zero,
    );
  });
}
