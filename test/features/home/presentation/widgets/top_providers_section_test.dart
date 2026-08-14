import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/service_type.dart';
import 'package:guiautomotriz_mobile/core/router/route_names.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/home_item.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/top_providers_result.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/sections/top_providers_section.dart';

void main() {
  const serviceType = ServiceType.workshops;

  HomeItem fixture({
    String id = 'workshop-1',
    String name = 'Taller Norte',
    int reviews = 24,
    double? distanceKm = 2.4,
    bool? isOpen = true,
    String? photo,
    ServiceType type = serviceType,
  }) =>
      HomeItem(
        id: id,
        name: name,
        detail: 'Diagnóstico y frenos',
        rating: 4.8,
        reviews: reviews,
        distanceKm: distanceKm,
        isOpen: isOpen,
        iconName: 'warehouse_outlined',
        type: type,
        photo: photo,
      );

  Widget app({
    required List<Override> overrides,
    ServiceType type = serviceType,
    double textScale = 1,
    bool disableAnimations = false,
  }) {
    final routePath = type == ServiceType.mechanic
        ? RouteNames.mechanics
        : RouteNames.workshops;
    final title = type == ServiceType.mechanic
        ? 'Mecánicos mejor valorados'
        : 'Talleres mejor valorados';
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(
            body: TopProvidersSection(
              serviceType: type,
              title: title,
              routePath: routePath,
            ),
          ),
        ),
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

    return ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          child: child!,
        ),
      ),
    );
  }

  Widget subject(
    AsyncValue<List<HomeItem>> state, {
    ServiceType type = serviceType,
    double textScale = 1,
    bool disableAnimations = false,
  }) =>
      app(
        type: type,
        textScale: textScale,
        disableAnimations: disableAnimations,
        overrides: [
          topProvidersProvider.overrideWith((ref, providerType) => state),
        ],
      );

  Widget subjectFromTopProviders(
    Future<TopProvidersResult> Function(Ref ref) loader,
  ) =>
      app(
        overrides: [
          homeTopProvidersProvider.overrideWith(loader),
        ],
      );

  testWidgets('shows three skeletons while providers load', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(375, 800));
    await tester.pumpWidget(subject(const AsyncValue.loading()));

    final firstSkeleton = find.byKey(const Key('top-provider-skeleton-1'));
    expect(firstSkeleton, findsOneWidget);

    final skeletonList =
        find.byKey(const Key('top-providers-skeleton-horizontal-list'));
    final skeletonListRect = tester.getRect(skeletonList);
    expect(skeletonListRect.left, 20);
    expect(skeletonListRect.right, 355);

    final media =
        find.byKey(const Key('top-provider-skeleton-media-workshops-1'));
    expect(media, findsOneWidget);
    expect(tester.getSize(media).width, 327);
    expect(tester.getSize(media).height, closeTo(183.9375, 0.1));
  });

  testWidgets('shows an empty state and navigates to all workshops',
      (tester) async {
    await tester.pumpWidget(subject(const AsyncValue.data([])));

    expect(find.text('Todavía no hay talleres valorados'), findsOneWidget);
    expect(find.text('Ver todos'), findsOneWidget);

    await tester.tap(find.text('Ver todos'));
    await tester.pumpAndSettle();

    expect(find.text('workshops-route'), findsOneWidget);
  });

  testWidgets('shows recoverable copy without exposing provider errors',
      (tester) async {
    await tester.pumpWidget(
      subject(AsyncValue.error(Exception('database secret'), StackTrace.empty)),
    );

    expect(find.text('No pudimos cargar los talleres'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.textContaining('database secret'), findsNothing);
  });

  testWidgets('uses the mechanic noun in the empty state', (tester) async {
    await tester.pumpWidget(
      subject(const AsyncValue.data([]), type: ServiceType.mechanic),
    );

    expect(find.text('Todavía no hay mecánicos valorados'), findsOneWidget);
  });

  testWidgets('uses the mechanic noun in the error state', (tester) async {
    await tester.pumpWidget(
      subject(
        AsyncValue.error(Exception('database secret'), StackTrace.empty),
        type: ServiceType.mechanic,
      ),
    );

    expect(find.text('No pudimos cargar los mecánicos'), findsOneWidget);
  });

  testWidgets('retries the source provider and renders recovered providers',
      (tester) async {
    var loads = 0;
    await tester.pumpWidget(
      subjectFromTopProviders((ref) async {
        loads++;
        if (loads == 1) throw Exception('database secret');
        return TopProvidersResult(
          workshops: [fixture()],
          mechanics: const [],
        );
      }),
    );
    await tester.pumpAndSettle();

    expect(find.text('No pudimos cargar los talleres'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(loads, 2);
    expect(find.text('Taller Norte'), findsOneWidget);
  });

  testWidgets('shows provider without rank and keeps honest social proof',
      (tester) async {
    await tester.pumpWidget(subject(AsyncValue.data([fixture()])));

    expect(find.text('1'), findsNothing);
    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('24 reseñas'), findsOneWidget);
    expect(find.text('2.4 km'), findsOneWidget);
    expect(find.text('Abierto'), findsOneWidget);
  });

  testWidgets('announces each provider card with one consolidated label',
      (tester) async {
    await tester.pumpWidget(subject(AsyncValue.data([fixture()])));

    expect(
      find.bySemanticsLabel('Ver detalles de Taller Norte'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Puesto 1'), findsNothing);
  }, semanticsEnabled: true);

  testWidgets('reserves 16:9 workshop media even when its photo is missing',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(375, 800));
    await tester.pumpWidget(subject(AsyncValue.data([fixture()])));

    final card = find.bySemanticsLabel('Ver detalles de Taller Norte');
    final media = find.byKey(const Key('top-provider-media-workshop-1'));
    expect(media, findsOneWidget);
    expect(tester.getSize(media).width, tester.getSize(card).width);
    expect(tester.getSize(media).width, 327);
    expect(tester.getSize(media).height, closeTo(183.9375, 0.1));
    expect(tester.getTopLeft(media), tester.getTopLeft(card));
  });

  testWidgets('lays multiple providers in a horizontal sequence',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(430, 800));
    await tester.pumpWidget(
      subject(
        AsyncValue.data([
          fixture(),
          fixture(id: 'workshop-2', name: 'Taller Este'),
          fixture(id: 'workshop-3', name: 'Taller Sur'),
        ]),
      ),
    );

    final first = find.bySemanticsLabel('Ver detalles de Taller Norte');
    final second = find.bySemanticsLabel('Ver detalles de Taller Este');
    final horizontalList =
        find.byKey(const Key('top-providers-horizontal-list'));
    final listRect = tester.getRect(horizontalList);
    expect(listRect.left, 20);
    expect(listRect.right, 410);
    expect(tester.widget<ListView>(horizontalList).clipBehavior, Clip.hardEdge);
    expect(tester.getTopLeft(first).dx, listRect.left);
    expect(
        tester.getTopLeft(second).dx, greaterThan(tester.getTopLeft(first).dx));
    expect(tester.getTopLeft(second).dy,
        closeTo(tester.getTopLeft(first).dy, 0.1));
    expect(
      horizontalList,
      findsOneWidget,
    );
  }, semanticsEnabled: true);

  for (final type in const [ServiceType.workshops, ServiceType.mechanic]) {
    testWidgets(
        'gently reveals more ${type.name} providers and returns to the start',
        (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(430, 800));
      await tester.pumpWidget(
        subject(
          AsyncValue.data([
            fixture(
              id: '${type.name}-1',
              type: type,
            ),
            fixture(
              id: '${type.name}-2',
              name: 'Segundo proveedor',
              type: type,
            ),
          ]),
          type: type,
        ),
      );

      final list = find.byKey(const Key('top-providers-horizontal-list'));
      final scrollable = find.descendant(
        of: list,
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable).position;

      expect(position.pixels, 0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 325));
      expect(position.pixels, greaterThan(0));

      await tester.pumpAndSettle();
      expect(position.pixels, closeTo(0, 0.1));
    });
  }

  testWidgets('does not animate the provider hint when motion is reduced',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(430, 800));
    await tester.pumpWidget(
      subject(
        AsyncValue.data([
          fixture(),
          fixture(id: 'workshop-2', name: 'Taller Este'),
        ]),
        disableAnimations: true,
      ),
    );

    final list = find.byKey(const Key('top-providers-horizontal-list'));
    final scrollable = find.descendant(
      of: list,
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable).position;

    await tester.pump(const Duration(seconds: 2));
    expect(position.pixels, 0);
  });

  testWidgets('uses 16:9 workshop media and a compact mechanic portrait',
      (tester) async {
    await tester.pumpWidget(
      subject(
        AsyncValue.data([
          fixture(photo: 'https://example.com/workshop.jpg'),
        ]),
      ),
    );

    final workshopPhoto =
        find.byKey(const Key('top-provider-workshop-photo-workshop-1'));
    expect(workshopPhoto, findsOneWidget);
    final workshopCard = find.bySemanticsLabel('Ver detalles de Taller Norte');
    expect(
      tester.getSize(workshopPhoto).width,
      tester.getSize(workshopCard).width,
    );
    expect(
      tester.getSize(workshopPhoto).height,
      closeTo(tester.getSize(workshopPhoto).width * 9 / 16, 0.1),
    );
    expect(
      tester.getBottomRight(workshopPhoto).dy,
      lessThan(tester.getTopLeft(find.text('Taller Norte')).dy),
    );
    final workshopHeight = tester.getSize(workshopCard).height;

    await tester.pumpWidget(
      subject(
        AsyncValue.data([
          fixture(
            id: 'mechanic-1',
            name: 'Pedro Pérez',
            photo: 'https://example.com/mechanic.jpg',
            type: ServiceType.mechanic,
          ),
        ]),
        type: ServiceType.mechanic,
      ),
    );

    final mechanicAvatar =
        find.byKey(const Key('top-provider-mechanic-avatar-mechanic-1'));
    expect(mechanicAvatar, findsOneWidget);
    expect(tester.getSize(mechanicAvatar), const Size(76, 76));
    expect(
      find.ancestor(of: mechanicAvatar, matching: find.byType(ClipOval)),
      findsOneWidget,
    );
    final mechanicCard = find.bySemanticsLabel('Ver detalles de Pedro Pérez');
    final mechanicHeight = tester.getSize(mechanicCard).height;

    final decoration = tester.widget<DecoratedBox>(
      find.byKey(const Key('top-provider-card-decoration-mechanic-1')),
    );
    final boxDecoration = decoration.decoration as BoxDecoration;
    final material = tester.widget<Material>(
      find.byKey(const Key('top-provider-card-surface-mechanic-1')),
    );
    final shape = material.shape! as RoundedRectangleBorder;

    expect(mechanicHeight, 164);
    expect(mechanicHeight, lessThan(workshopHeight));
    expect(boxDecoration.boxShadow, isNotEmpty);
    expect(shape.side.width, greaterThan(0));
    expect(shape.side.color, isNot(Colors.transparent));
  });

  testWidgets('keeps each missing provider photo in its intended shape',
      (tester) async {
    await tester.pumpWidget(subject(AsyncValue.data([fixture()])));

    final workshopFallback =
        find.byKey(const Key('top-provider-workshop-fallback-workshop-1'));
    expect(workshopFallback, findsOneWidget);
    expect(
      tester.getSize(workshopFallback).height,
      closeTo(tester.getSize(workshopFallback).width * 9 / 16, 0.1),
    );
    expect(
      tester.getSize(workshopFallback).width,
      tester
          .getSize(find.bySemanticsLabel('Ver detalles de Taller Norte'))
          .width,
    );

    await tester.pumpWidget(
      subject(
        AsyncValue.data([
          fixture(
            id: 'mechanic-1',
            name: 'Pedro Pérez',
            type: ServiceType.mechanic,
          ),
        ]),
        type: ServiceType.mechanic,
      ),
    );

    final mechanicFallback =
        find.byKey(const Key('top-provider-mechanic-fallback-mechanic-1'));
    expect(mechanicFallback, findsOneWidget);
    expect(tester.getSize(mechanicFallback), const Size(76, 76));
    expect(
      find.ancestor(of: mechanicFallback, matching: find.byType(ClipOval)),
      findsOneWidget,
    );
  }, semanticsEnabled: true);

  testWidgets('overlays workshop availability in the lower media corner',
      (tester) async {
    await tester.pumpWidget(subject(AsyncValue.data([fixture()])));

    final media = find.byKey(const Key('top-provider-media-workshop-1'));
    final availability =
        find.byKey(const Key('top-provider-availability-workshop-1'));
    expect(availability, findsOneWidget);
    expect(
      find.descendant(of: media, matching: availability),
      findsOneWidget,
    );

    final mediaRect = tester.getRect(media);
    final availabilityRect = tester.getRect(availability);
    expect(availabilityRect.left, lessThan(mediaRect.center.dx));
    expect(availabilityRect.center.dy, greaterThan(mediaRect.center.dy));
    expect(availabilityRect.bottom, lessThanOrEqualTo(mediaRect.bottom));
  });

  testWidgets('labels a provider with no reviews honestly', (tester) async {
    await tester.pumpWidget(subject(AsyncValue.data([fixture(reviews: 0)])));

    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('Sin reseñas'), findsOneWidget);
  });

  testWidgets(
      'does not invent distance or open status when metadata is missing',
      (tester) async {
    await tester.pumpWidget(
      subject(
        AsyncValue.data([
          fixture(distanceKm: null, isOpen: null),
        ]),
      ),
    );

    expect(find.text('Distancia no disponible'), findsOneWidget);
    expect(find.text('Horario no disponible'), findsOneWidget);
    expect(find.text('0.0 km'), findsNothing);
    expect(find.text('Abierto'), findsNothing);
  });

  testWidgets('keeps provider information available on small and large phones',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in const [Size(320, 720), Size(480, 900)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(subject(AsyncValue.data([fixture()])));

      expect(find.text('Taller Norte'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('keeps all provider metadata at supported scaled phone layouts',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final flutterErrors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = flutterErrors.add;
    addTearDown(() => FlutterError.onError = previousOnError);

    final cases = [
      (ServiceType.workshops, fixture()),
      (
        ServiceType.mechanic,
        fixture(
          id: 'mechanic-1',
          name: 'Pedro Pérez',
          type: ServiceType.mechanic,
        ),
      ),
    ];

    for (final width in const [335.0, 375.0, 430.0]) {
      for (final scale in const [1.0, 1.3, 2.0]) {
        for (final providerCase in cases) {
          await tester.binding.setSurfaceSize(Size(width, 900));
          await tester.pumpWidget(
            subject(
              AsyncValue.data([providerCase.$2]),
              type: providerCase.$1,
              textScale: scale,
            ),
          );

          expect(find.text(providerCase.$2.name), findsOneWidget);
          expect(find.text('4.8'), findsOneWidget);
          expect(find.text('24 reseñas'), findsOneWidget);
          expect(find.text('2.4 km'), findsOneWidget);
          expect(find.text('Abierto'), findsOneWidget);
          expect(find.text('Diagnóstico y frenos'), findsOneWidget);
        }
      }
    }

    expect(
      flutterErrors.where(
        (details) => details.exceptionAsString().contains('overflowed'),
      ),
      isEmpty,
    );
    expect(flutterErrors, isEmpty);
  });
}
