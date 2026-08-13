import 'dart:async';

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
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/promo_carousel.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/sections/top_providers_section.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_page.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/store_dashboard/store_dashboard_view.dart';
import 'package:guiautomotriz_mobile/features/reports/domain/entities/store_dashboard.dart';
import 'package:guiautomotriz_mobile/features/reports/presentation/providers/reports_provider.dart';
import 'package:guiautomotriz_mobile/features/vehicles/domain/entities/user_car.dart';
import 'package:guiautomotriz_mobile/features/vehicles/presentation/providers/vehicle_providers.dart';
import 'package:guiautomotriz_mobile/shared/widgets/skeleton_loader.dart';
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

  void authenticateAs(User user) {
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }
}

void main() {
  const consumer = User(
    id: 'consumer-1',
    email: 'elio@example.com',
    name: 'Elio',
    role: UserRole.consumer,
  );
  const store = User(
    id: 'store-1',
    email: 'store@example.com',
    name: 'Repuestos Norte',
    role: UserRole.store,
  );
  const mechanic = User(
    id: 'mechanic-1',
    email: 'mechanic@example.com',
    name: 'Mecánico Norte',
    role: UserRole.mechanic,
  );
  const car = UserCar(
    id: 'car-1',
    brand: 'Toyota',
    model: 'Corolla',
    year: 2022,
  );
  const promo = Promo(
    title: 'Revisión de frenos con descuento',
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
    User user = consumer,
    _TestAuthNotifier? authNotifier,
    ServiceType? initialServiceType,
    Future<List<Promo>> Function(Ref ref, ServiceType type)? loadPromos,
  }) {
    final notifier = authNotifier ??
        _TestAuthNotifier(
          AuthState(status: AuthStatus.authenticated, user: user),
        );
    return ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => notifier),
        if (initialServiceType != null)
          selectedServiceTypeProvider.overrideWith(
            (ref) => initialServiceType,
          ),
        userCarsProvider.overrideWith((ref) async => const [car]),
        locationServiceProvider.overrideWithValue(_FakeLocationService()),
        adsAsPromosProvider.overrideWith(
          loadPromos ?? (ref, type) async => const [],
        ),
        topProvidersProvider.overrideWith((ref, type) {
          return type == ServiceType.workshops ? workshops : mechanics;
        }),
        storeDashboardProvider.overrideWith(
          (ref) => Completer<DashboardResponse>().future,
        ),
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

  testWidgets('consumer Home places provider groups in keyed surfaces',
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
      loadPromos: (ref, type) async => const [promo],
    );
    addTearDown(container.dispose);

    await pumpHome(tester, container, height: 1800);

    final promoFinder = find.text('Revisión de frenos con descuento');
    final workshopsSurface =
        find.byKey(const Key('home-provider-section-workshops'));
    final mechanicsSurface =
        find.byKey(const Key('home-provider-section-mechanics'));
    expect(workshopsSurface, findsOneWidget);
    expect(mechanicsSurface, findsOneWidget);
    expect(
      tester.getTopLeft(promoFinder).dy,
      lessThan(tester.getTopLeft(workshopsSurface).dy),
    );

    final workshopsSection = tester.widget<TopProvidersSection>(
      find.descendant(
        of: workshopsSurface,
        matching: find.byType(TopProvidersSection),
      ),
    );
    expect(workshopsSection.serviceType, ServiceType.workshops);
    final mechanicsSection = tester.widget<TopProvidersSection>(
      find.descendant(
        of: mechanicsSurface,
        matching: find.byType(TopProvidersSection),
      ),
    );
    expect(mechanicsSection.serviceType, ServiceType.mechanic);
  });

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
      loadPromos: (ref, type) async => const [promo],
    );
    addTearDown(container.dispose);

    await pumpHome(tester, container, height: 1800);

    const orderedLabels = [
      '¿Qué necesitas hoy?',
      'Pedir repuesto',
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

    final promoFinder = find.text('Revisión de frenos con descuento');
    expect(promoFinder, findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Pedir repuesto')).dy,
      lessThan(tester.getTopLeft(promoFinder).dy),
    );
    expect(
      tester.getTopLeft(promoFinder).dy,
      lessThan(tester.getTopLeft(find.text('Talleres mejor valorados')).dy),
    );

    final workshopsSurface =
        find.byKey(const Key('home-provider-section-workshops'));
    final mechanicsSurface =
        find.byKey(const Key('home-provider-section-mechanics'));
    expect(workshopsSurface, findsOneWidget);
    expect(mechanicsSurface, findsOneWidget);
    expect(
      tester.getTopLeft(workshopsSurface).dy,
      lessThan(tester.getTopLeft(mechanicsSurface).dy),
    );
    expect(
      tester.getTopLeft(promoFinder).dy,
      lessThan(tester.getTopLeft(workshopsSurface).dy),
    );

    expect(
      find.byKey(const Key('home-selected-vehicle-control')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('home-vehicle-chips-list')), findsNothing);

    final workshopsSection = tester.widget<TopProvidersSection>(
      find.descendant(
        of: workshopsSurface,
        matching: find.byType(TopProvidersSection),
      ),
    );
    expect(workshopsSection.serviceType, ServiceType.workshops);
    final mechanicsSection = tester.widget<TopProvidersSection>(
      find.descendant(
        of: mechanicsSurface,
        matching: find.byType(TopProvidersSection),
      ),
    );
    expect(mechanicsSection.serviceType, ServiceType.mechanic);
    expect(find.text('Mi garage'), findsNothing);
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('Compras'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image ==
                const AssetImage('assets/images/logo_icon_zoom.png'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'spare-part action uses the first garage car displayed by the header',
      (tester) async {
    final container = containerFor(
      workshops: const AsyncValue.data([]),
      mechanics: const AsyncValue.data([]),
    );
    addTearDown(container.dispose);

    await pumpHome(tester, container);

    expect(container.read(searchVehicleProvider), isNull);
    expect(find.text('Toyota Corolla · 2022'), findsOneWidget);

    await tester.tap(find.text('Pedir repuesto'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final wizard = tester.widget<SparePartWizardPage>(
      find.byType(SparePartWizardPage),
    );
    expect(wizard.initialVehicle, car);
  });

  testWidgets('consumer ignores a stale store dashboard selection',
      (tester) async {
    final container = containerFor(
      workshops: const AsyncValue.data([]),
      mechanics: const AsyncValue.data([]),
      initialServiceType: ServiceType.storeDashboard,
    );
    addTearDown(container.dispose);

    await pumpHome(tester, container);

    expect(find.byType(StoreDashboardView), findsNothing);
    expect(find.text('¿Qué necesitas hoy?'), findsOneWidget);
    expect(find.text('Talleres mejor valorados'), findsOneWidget);
  });

  testWidgets('store to consumer role transition replaces a stale dashboard',
      (tester) async {
    final authNotifier = _TestAuthNotifier(
      const AuthState(status: AuthStatus.authenticated, user: store),
    );
    final container = containerFor(
      workshops: const AsyncValue.data([]),
      mechanics: const AsyncValue.data([]),
      authNotifier: authNotifier,
      initialServiceType: ServiceType.storeDashboard,
    );
    addTearDown(container.dispose);

    await pumpHome(tester, container);
    expect(find.byType(StoreDashboardView), findsOneWidget);
    expect(find.text('¿Qué necesitas hoy?'), findsNothing);

    authNotifier.authenticateAs(consumer);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(StoreDashboardView), findsNothing);
    expect(find.text('¿Qué necesitas hoy?'), findsOneWidget);
    expect(find.text('Talleres mejor valorados'), findsOneWidget);
  });

  testWidgets('mechanic Home keeps only its role-allowed service sections',
      (tester) async {
    final container = containerFor(
      workshops: const AsyncValue.data([]),
      mechanics: const AsyncValue.data([]),
      user: mechanic,
      initialServiceType: ServiceType.spareParts,
    );
    addTearDown(container.dispose);

    await pumpHome(tester, container);
    await tester.fling(homeListView(), const Offset(0, -1600), 5000);
    await tester.pump();

    expect(find.text('Talleres cerca de ti'), findsOneWidget);
    expect(find.text('Mecánicos cerca de ti'), findsNothing);
    expect(find.text('Pedir repuesto'), findsOneWidget);
    expect(find.text('Buscar mecánico'), findsNothing);
  });

  testWidgets('consumer Home shows an ad skeleton while promos load',
      (tester) async {
    final pendingPromos = Completer<List<Promo>>();
    final container = containerFor(
      workshops: const AsyncValue.data([]),
      mechanics: const AsyncValue.data([]),
      loadPromos: (ref, type) => pendingPromos.future,
    );
    addTearDown(container.dispose);

    await pumpHome(tester, container);

    expect(find.byType(PromoSkeleton), findsOneWidget);
    expect(find.byType(PromoCarousel), findsNothing);
  });

  testWidgets('consumer Home keeps a retryable ad slot after promo errors',
      (tester) async {
    var attempts = 0;
    final container = containerFor(
      workshops: const AsyncValue.data([]),
      mechanics: const AsyncValue.data([]),
      loadPromos: (ref, type) async {
        attempts += 1;
        if (attempts == 1) {
          throw StateError('private advertising secret');
        }
        return const [promo];
      },
    );
    addTearDown(container.dispose);

    await pumpHome(tester, container);

    expect(find.byType(PromoCarousel), findsNothing);
    expect(find.byType(PromoSkeleton), findsNothing);
    expect(find.byKey(const Key('promo-error-card')), findsOneWidget);
    expect(find.text('No pudimos cargar la publicidad'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.textContaining('private advertising secret'), findsNothing);
    expect(find.text('Talleres mejor valorados'), findsOneWidget);

    final actionY = tester.getBottomLeft(find.text('Pedir repuesto')).dy;
    final promoY =
        tester.getTopLeft(find.byKey(const Key('promo-error-card'))).dy;
    final workshopsY =
        tester.getTopLeft(find.text('Talleres mejor valorados')).dy;
    expect(actionY, lessThan(promoY));
    expect(promoY, lessThan(workshopsY));

    await tester.ensureVisible(find.text('Reintentar'));
    await tester.pump();
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(attempts, 2);
    expect(find.byKey(const Key('promo-error-card')), findsNothing);
    expect(find.text('Revisión de frenos con descuento'), findsOneWidget);
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
    final errorContexts = <String>[];
    final missingContent = <String>[];
    var activeMatrixCase = 'width=unknown, textScale=unknown';
    FlutterError.onError = (error) {
      errors.add(error);
      errorContexts.add(
        '$activeMatrixCase: ${error.exceptionAsString()}',
      );
    };
    addTearDown(() => tester.binding.setSurfaceSize(null));

    try {
      for (final width in const [375.0, 430.0]) {
        for (final textScale in const [1.0, 1.3, 2.0]) {
          activeMatrixCase = 'width=$width, textScale=$textScale';
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
            missingContent.add(activeMatrixCase);
          }
          container.dispose();
        }
      }
    } finally {
      FlutterError.onError = previousOnError;
    }

    expect(
      missingContent,
      isEmpty,
      reason: 'Missing content at: ${missingContent.join(', ')}',
    );
    expect(
      errors,
      isEmpty,
      reason: errorContexts.join('\n'),
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
