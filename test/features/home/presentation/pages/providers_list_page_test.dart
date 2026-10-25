import 'package:guiautomotriz_mobile/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:guiautomotriz_mobile/features/catalog/domain/entities/specialty.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/sort_option.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/home_list_header.dart';
import 'package:guiautomotriz_mobile/shared/widgets/app_chip.dart';
import 'package:guiautomotriz_mobile/shared/widgets/app_search_field.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:guiautomotriz_mobile/core/error/failures.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/home_filters.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/provider_search_page.dart';
import 'package:guiautomotriz_mobile/features/home/domain/repositories/home_repository.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/service_type.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/user_role.dart';
import 'package:guiautomotriz_mobile/core/storage/secure_storage.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/entities/user.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/register_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/upload_avatar_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/providers/auth_state.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/home_item.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/pages/providers_list_page.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:guiautomotriz_mobile/shared/widgets/skeleton_loader.dart';
import 'package:mocktail/mocktail.dart';

class _MockHomeRepository extends Mock implements HomeRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSecureStorage extends Mock implements SecureStorage {}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier({UserRole role = UserRole.store})
      : super(
          loginUseCase: LoginUseCase(_MockAuthRepository()),
          registerUseCase: RegisterUseCase(_MockAuthRepository()),
          updateProfileUseCase: UpdateProfileUseCase(_MockAuthRepository()),
          uploadAvatarUseCase: UploadAvatarUseCase(_MockAuthRepository()),
          authRepository: _MockAuthRepository(),
          secureStorage: _MockSecureStorage(),
        ) {
    state = AuthState(
      status: AuthStatus.authenticated,
      user: User(
        id: 'store-1',
        email: 'store@example.com',
        name: 'Repuestos Norte',
        role: role,
      ),
    );
  }

  @override
  Future<void> checkAuthStatus() async {}
}

class _StaticPagination extends PaginatedProvidersNotifier {
  final AsyncValue<List<HomeItem>> initial;
  _StaticPagination(this.initial);

  @override
  Future<ProvidersListState> build(ServiceType arg) => initial.when(
        data: (items) async =>
            ProvidersListState(items: items, total: items.length),
        error: (error, stack) => Future.error(error, stack),
        loading: () => Completer<ProvidersListState>().future,
      );
}

Widget _subject({
  required AsyncValue<List<HomeItem>> state,
  required Size size,
  required EdgeInsets padding,
  double textScale = 1,
  bool disableAnimations = false,
  ServiceType serviceType = ServiceType.workshops,
  UserRole role = UserRole.store,
  HomeRepository? repository,
}) {
  return ProviderScope(
    key: UniqueKey(),
    overrides: [
      authProvider.overrideWith((ref) => _TestAuthNotifier(role: role)),
      specialtiesProvider.overrideWith((ref) async => const [
            Specialty(id: 'brakes', name: 'Frenos'),
            Specialty(id: 'engine', name: 'Motor'),
          ]),
      if (repository == null)
        paginatedProvidersProvider.overrideWith(() => _StaticPagination(state))
      else ...[
        homeRepositoryProvider.overrideWithValue(repository),
        providerSearchFiltersProvider
            .overrideWith((ref) async => ref.watch(homeFiltersProvider)),
      ],
    ],
    child: MediaQuery(
      data: MediaQueryData(
        size: size,
        padding: padding,
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: MaterialApp(
        home: ProvidersListPage(serviceType: serviceType),
      ),
    ),
  );
}

void main() {
  setUpAll(() => registerFallbackValue(const HomeFilters()));

  for (final type in [ServiceType.workshops, ServiceType.mechanic]) {
    testWidgets(
        'applies all ${type.name} filters without showing selections or blank filter rows on the list',
        (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(430, 932));
      final repository = _MockHomeRepository();
      final requestedFilters = <HomeFilters>[];
      when(() => repository.searchProvidersPage(
          type: type,
          filters: any(named: 'filters'),
          page: any(named: 'page'))).thenAnswer((invocation) async {
        requestedFilters
            .add(invocation.namedArguments[#filters] as HomeFilters);
        return Right(ProviderSearchPage(items: [
          HomeItem(
              id: 'matching',
              name: 'Taller compatible',
              detail: 'Frenos y motor',
              rating: 4.9,
              reviews: 5,
              distanceKm: 1,
              isOpen: true,
              iconName: 'warehouse_outlined',
              type: type)
        ], total: 1, page: 1, pageSize: 20));
      });
      await tester.pumpWidget(_subject(
          state: const AsyncData([]),
          size: const Size(430, 932),
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          disableAnimations: true,
          repository: repository,
          serviceType: type));
      await tester.pumpAndSettle();
      final headerHeight = tester.getSize(find.byType(HomeListHeader)).height;
      await tester.tap(find.bySemanticsLabel('Filtros de búsqueda'));
      await tester.pumpAndSettle();
      for (final label in [
        'Más cercanos',
        '50 km',
        '4.5+ ★',
        'Frenos',
        'Motor'
      ]) {
        final chip = find.widgetWithText(AppChip, label);
        await tester.ensureVisible(chip);
        await tester.tap(chip);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Aplicar (4)'));
      await tester.pumpAndSettle();
      expect(
          requestedFilters.last,
          const HomeFilters(
              sortBy: SortOption.cercania,
              radioKm: 50,
              minRating: 4.5,
              specialtyIds: ['brakes', 'engine']));
      expect(find.text('Taller compatible'), findsOneWidget);
      expect(find.byType(AppChip), findsNothing);
      expect(find.text('Quitar filtros'), findsNothing);
      expect(tester.getSize(find.byType(HomeListHeader)).height, headerHeight);
      expect(
          tester
              .widget<AppSearchField>(find.byType(AppSearchField))
              .activeFilters,
          0);
      expect(tester.takeException(), isNull);

      await tester.tap(find.bySemanticsLabel('Filtros de búsqueda'));
      await tester.pumpAndSettle();
      for (final label in [
        'Más cercanos',
        '50 km',
        '4.5+ ★',
        'Frenos',
        'Motor'
      ]) {
        expect(
            tester
                .widget<AppChip>(find.widgetWithText(AppChip, label))
                .selected,
            isTrue);
      }
      final requestCount = requestedFilters.length;
      await tester.ensureVisible(find.widgetWithText(AppChip, '5 km'));
      await tester.tap(find.widgetWithText(AppChip, '5 km'));
      await tester.tap(find.bySemanticsLabel('Cerrar filtros'));
      await tester.pumpAndSettle();
      expect(requestedFilters.length, requestCount);
      await tester.tap(find.bySemanticsLabel('Filtros de búsqueda'));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<AppChip>(find.widgetWithText(AppChip, '50 km'))
              .selected,
          isTrue);
      await tester.tap(find.text('Limpiar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aplicar filtros'));
      await tester.pumpAndSettle();
      expect(requestedFilters.last, const HomeFilters());
      expect(find.byType(AppChip), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final type in [ServiceType.workshops, ServiceType.mechanic]) {
    testWidgets('scroll fetches beyond 20 ${type.name} and reaches the end',
        (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(430, 932));
      final repository = _MockHomeRepository();
      final requests = <int>[];
      when(() => repository.searchProvidersPage(
          type: type,
          filters: any(named: 'filters'),
          page: any(named: 'page'))).thenAnswer((invocation) async {
        final page = invocation.namedArguments[#page] as int;
        requests.add(page);
        return Right(ProviderSearchPage(
          items: List.generate(
              page == 1 ? 20 : 3,
              (index) => HomeItem(
                    id: '${(page - 1) * 20 + index}',
                    name: 'Proveedor ${(page - 1) * 20 + index + 1}',
                    detail: 'Frenos',
                    rating: 4,
                    reviews: 1,
                    distanceKm: 1,
                    isOpen: true,
                    iconName: 'build_outlined',
                    type: type,
                  )),
          total: 23,
          page: page,
          pageSize: 20,
        ));
      });
      await tester.pumpWidget(_subject(
          state: const AsyncData([]),
          size: const Size(430, 932),
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          serviceType: type,
          disableAnimations: true,
          repository: repository));
      await tester.pumpAndSettle();
      expect(requests, [1]);
      await tester.scrollUntilVisible(find.text('Proveedor 23'), 400,
          scrollable: find.byType(Scrollable).first, maxScrolls: 30);
      await tester.pumpAndSettle();
      expect(find.text('Proveedor 23'), findsOneWidget);
      expect(find.text('Has visto todos los resultados'), findsOneWidget);
      expect(find.byTooltip('Página siguiente'), findsNothing);
      expect(requests, [1, 2]);
      final scrollable =
          tester.state<ScrollableState>(find.byType(Scrollable).first);
      expect(scrollable.position.pixels, greaterThan(1000));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'shows loading, retains cards on error and offers an accessible retry',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(430, 932));
    final repository = _MockHomeRepository();
    final pending = Completer<Either<Failure, ProviderSearchPage>>();
    var calls = 0;
    ProviderSearchPage page(int page) => ProviderSearchPage(items: [
          HomeItem(
              id: '$page',
              name: 'Taller $page',
              detail: 'Frenos',
              rating: 4,
              reviews: 1,
              distanceKm: 1,
              isOpen: true,
              iconName: 'build_outlined',
              type: ServiceType.workshops)
        ], total: 2, page: page, pageSize: 1);
    when(() => repository.searchProvidersPage(
        type: ServiceType.workshops,
        filters: any(named: 'filters'),
        page: any(named: 'page'))).thenAnswer((invocation) async {
      calls++;
      if (calls == 2) return pending.future;
      return Right(page(invocation.namedArguments[#page] as int));
    });
    await tester.pumpWidget(_subject(
        state: const AsyncData([]),
        size: const Size(430, 932),
        padding: const EdgeInsets.only(top: 59, bottom: 34),
        disableAnimations: true,
        repository: repository));
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
    expect(find.text('Taller 1'), findsOneWidget);
    expect(find.text('Cargando más resultados…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    pending.complete(const Left(NetworkFailure()));
    await tester.pumpAndSettle();
    expect(find.text('Taller 1'), findsOneWidget);
    expect(find.text('No pudimos cargar más resultados.'), findsOneWidget);
    final retry = find.widgetWithText(OutlinedButton, 'Reintentar');
    expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));
    expect(tester.getBottomRight(retry).dy, lessThanOrEqualTo(932 - 34));
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(find.text('Taller 1'), findsOneWidget);
    expect(find.text('Taller 2'), findsOneWidget);
    expect(find.text('No pudimos cargar más resultados.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search finds a provider on an unloaded page', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(375, 812));
    final repository = _MockHomeRepository();
    final requests = <int>[];
    when(() => repository.searchProvidersPage(
        type: ServiceType.workshops,
        filters: any(named: 'filters'),
        page: any(named: 'page'))).thenAnswer((invocation) async {
      final page = invocation.namedArguments[#page] as int;
      requests.add(page);
      return Right(ProviderSearchPage(
          items: List.generate(
              page == 1 ? 20 : 1,
              (index) => HomeItem(
                  id: '$page-$index',
                  name: page == 1 ? 'Taller $index' : 'Especialista lejano',
                  detail: 'Frenos',
                  rating: 4,
                  reviews: 1,
                  distanceKm: 1,
                  isOpen: true,
                  iconName: 'build_outlined',
                  type: ServiceType.workshops)),
          total: 21,
          page: page,
          pageSize: 20));
    });
    await tester.pumpWidget(_subject(
        state: const AsyncData([]),
        size: const Size(375, 812),
        padding: const EdgeInsets.only(top: 44, bottom: 34),
        disableAnimations: true,
        repository: repository));
    await tester.pumpAndSettle();
    expect(requests, [1]);
    await tester.enterText(find.byType(TextField), 'Especialista');
    await tester.pumpAndSettle();
    expect(requests, [1, 2]);
    expect(find.text('Especialista lejano'), findsOneWidget);
    expect(find.text('Sin resultados para "Especialista"'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final serviceType in [ServiceType.workshops, ServiceType.mechanic]) {
    testWidgets(
      'shows the ${serviceType.name} list without a vehicle selector',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(const Size(430, 932));

        await tester.pumpWidget(
          _subject(
            state: const AsyncValue.data([]),
            size: const Size(430, 932),
            padding: const EdgeInsets.only(top: 59, bottom: 34),
            serviceType: serviceType,
            role: UserRole.consumer,
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.text('Selecciona el vehículo'), findsNothing);
        expect(find.text('TU VEHÍCULO'), findsNothing);
        expect(find.text('Elegir'), findsNothing);
        expect(find.bySemanticsLabel('Elegir vehículo'), findsNothing);
        expect(find.byKey(const Key('vehicle-context-card')), findsNothing);
        expect(find.text('Aún no hay resultados en tu zona'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'lays out the pinned search header at the reported phone dimensions',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        _subject(
          state: const AsyncValue.data([]),
          size: const Size(430, 932),
          padding: const EdgeInsets.only(top: 59, bottom: 34),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Talleres cerca de tu negocio'), findsOneWidget);

      final backButton = find.ancestor(
        of: find.byIcon(Icons.arrow_back_rounded),
        matching: find.byType(IconButton),
      );
      expect(tester.getSize(backButton).shortestSide, greaterThanOrEqualTo(48));

      final filterButton = find
          .ancestor(
            of: find.byIcon(Icons.tune_rounded),
            matching: find.byType(GestureDetector),
          )
          .first;
      expect(
        tester.getSize(filterButton).shortestSide,
        greaterThanOrEqualTo(48),
      );
    },
  );

  testWidgets('keeps the loading state layout-safe on a small phone',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(375, 667));

    await tester.pumpWidget(
      _subject(
        state: const AsyncValue.loading(),
        size: const Size(375, 667),
        padding: const EdgeInsets.only(top: 24),
        disableAnimations: true,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(ItemCardSkeleton), findsNWidgets(3));
  });

  testWidgets('renders the recoverable error state on a small phone',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(375, 812));

    await tester.pumpWidget(
      _subject(
        state: AsyncValue.error(Exception('network'), StackTrace.empty),
        size: const Size(375, 812),
        padding: const EdgeInsets.only(top: 44, bottom: 34),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('No pudimos cargar los resultados.'), findsOneWidget);
  });

  testWidgets('keeps data usable at 320px with doubled text and reduced motion',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 700));
    await tester.pumpWidget(_subject(
        state: const AsyncData([
          HomeItem(
              id: 'small',
              name: 'Taller pequeño',
              detail: 'Diagnóstico y frenos',
              rating: 4.8,
              reviews: 2,
              distanceKm: 1,
              isOpen: true,
              iconName: 'warehouse_outlined',
              type: ServiceType.workshops)
        ]),
        size: const Size(320, 700),
        padding: const EdgeInsets.only(top: 24, bottom: 24),
        textScale: 2,
        disableAnimations: true));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.text('Has visto todos los resultados'), 250,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Has visto todos los resultados'), findsOneWidget);
  });

  testWidgets('renders data with large text and reduced motion',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(430, 932));

    await tester.pumpWidget(
      _subject(
        state: const AsyncValue.data([
          HomeItem(
            id: 'workshop-1',
            name: 'Taller Norte',
            detail: 'Diagnóstico y frenos',
            rating: 4.8,
            reviews: 24,
            distanceKm: 2.4,
            isOpen: true,
            iconName: 'warehouse_outlined',
            type: ServiceType.workshops,
          ),
        ]),
        size: const Size(430, 932),
        padding: const EdgeInsets.only(top: 59, bottom: 34),
        textScale: 2,
        disableAnimations: true,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Taller Norte'), findsOneWidget);
  });

  testWidgets(
      'reaches every loaded provider by scrolling without page controls',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(430, 932));

    final items = List.generate(
      7,
      (index) => HomeItem(
        id: 'workshop-$index',
        name: 'Taller ${index + 1}',
        detail: 'Diagnóstico y frenos',
        rating: 4.8,
        reviews: 24,
        distanceKm: 2.4,
        isOpen: true,
        iconName: 'warehouse_outlined',
        type: ServiceType.workshops,
      ),
    );

    await tester.pumpWidget(
      _subject(
        state: AsyncValue.data(items),
        size: const Size(430, 932),
        padding: const EdgeInsets.only(top: 59, bottom: 34),
        disableAnimations: true,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Taller 1'), findsOneWidget);
    expect(find.text('Taller 7'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Taller 7'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.byType(ItemCardSkeleton), findsNothing);
    expect(find.text('Taller 7'), findsOneWidget);
    expect(find.byTooltip('Página siguiente'), findsNothing);
  });
}
