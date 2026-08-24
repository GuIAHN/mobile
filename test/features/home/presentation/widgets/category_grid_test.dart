import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/service_type.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/user_role.dart';
import 'package:guiautomotriz_mobile/core/providers/current_user_provider.dart';
import 'package:guiautomotriz_mobile/core/router/route_names.dart';
import 'package:guiautomotriz_mobile/core/theme/app_colors.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/navigation/category_grid.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_page.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/entities/pending_review.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/providers/reviews_providers.dart';
import 'package:guiautomotriz_mobile/features/vehicles/domain/entities/user_car.dart';
import 'package:guiautomotriz_mobile/features/vehicles/presentation/providers/vehicle_providers.dart';

void main() {
  const actionLabels = <String>[
    'Pedir repuesto',
    'Buscar taller',
    'Buscar mecánico',
  ];
  const visibleActionLabels = <String>[
    'Pedir repuesto',
    'Buscar taller',
    'Buscar mecánico',
  ];

  const fixtureCar = UserCar(
    id: 'car-1',
    brand: 'Toyota',
    model: 'Corolla',
    year: 2022,
  );

  Widget subject({
    UserRole role = UserRole.consumer,
    UserCar? selectedVehicle,
    String? selectedVariantId,
    double width = 375,
    double textScale = 1,
    bool disableAnimations = false,
    List<PendingReview> pendingReviews = const [],
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(
            body: SingleChildScrollView(
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: width,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: CategoryGrid(),
                  ),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.workshops,
          builder: (_, __) => const Scaffold(
            body: Text('workshops-route'),
          ),
        ),
        GoRoute(
          path: RouteNames.mechanics,
          builder: (_, __) => const Scaffold(
            body: Text('mechanics-route'),
          ),
        ),
        GoRoute(
          path: RouteNames.pendingReviews,
          builder: (_, __) => const Scaffold(
            body: Text('pending-reviews-route'),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        currentRoleProvider.overrideWithValue(role),
        searchVehicleProvider.overrideWith((ref) => selectedVehicle),
        searchVehicleVariantIdProvider.overrideWith(
          (ref) => selectedVariantId,
        ),
        userCarsProvider.overrideWith((ref) async => const [fixtureCar]),
        pendingReviewsProvider.overrideWith((ref) async => pendingReviews),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 800),
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  testWidgets('consumer actions keep action titles and short subtitles',
      (tester) async {
    await tester.pumpWidget(subject());

    for (final label in visibleActionLabels) {
      expect(find.text(label), findsOneWidget);
    }
    for (final subtitle in const [
      'Cotiza piezas',
      'Opciones cercanas',
      'Servicio a domicilio',
    ]) {
      expect(find.text(subtitle), findsOneWidget);
    }

    await tester.tap(find.text('Buscar taller'));
    await tester.pumpAndSettle();
    expect(find.text('workshops-route'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buscar mecánico'));
    await tester.pumpAndSettle();
    expect(find.text('mechanics-route'), findsOneWidget);
  });

  testWidgets('blocks a new parts request and links to pending reviews',
      (tester) async {
    const pending = [
      PendingReview(
        targetId: 'store-user-1',
        providerProfileId: 'store-1',
        providerName: 'Tienda 1',
        conversationId: 'conversation-1',
      ),
      PendingReview(
        targetId: 'store-user-2',
        providerProfileId: 'store-2',
        providerName: 'Tienda 2',
        conversationId: 'conversation-2',
      ),
    ];

    await tester.pumpWidget(subject(pendingReviews: pending));
    await tester.tap(find.text('Pedir repuesto'));
    await tester.pumpAndSettle();

    expect(find.text('Tienes valoraciones pendientes'), findsOneWidget);
    expect(find.textContaining('Tienes 2 reseñas pendientes'), findsOneWidget);

    await tester.tap(find.text('IR A RESEÑAS PENDIENTES'));
    await tester.pumpAndSettle();
    expect(find.text('pending-reviews-route'), findsOneWidget);
    expect(find.byType(SparePartWizardPage), findsNothing);
  });

  testWidgets('uses centered icons, subtle borders and no arrow affordances',
      (tester) async {
    await tester.pumpWidget(subject());

    expect(find.text('¿Qué buscas hoy?'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    expect(find.byIcon(Icons.handyman_rounded), findsOneWidget);
    expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);
    expect(find.byIcon(Icons.engineering_rounded), findsOneWidget);
    expect(find.byType(Image), findsNothing);

    for (final label in actionLabels) {
      final isSelected = label == 'Pedir repuesto';
      final action = find.bySemanticsLabel(label);
      final decorations = tester
          .widgetList<Container>(
            find.descendant(of: action, matching: find.byType(Container)),
          )
          .map((container) => container.decoration)
          .whereType<BoxDecoration>();
      final cardDecoration =
          decorations.firstWhere((decoration) => decoration.boxShadow != null);
      final border = cardDecoration.border! as Border;

      expect(border.top.width, isSelected ? 2 : 1.25);
      expect(
        border.top.color,
        isSelected
            ? AppColors.primary
            : AppColors.primary.withValues(alpha: 0.22),
      );
    }
  });

  testWidgets('marks the current home action with a stronger border',
      (tester) async {
    await tester.pumpWidget(subject());

    final selectedAction = find.bySemanticsLabel('Pedir repuesto');
    final selectedData = tester.getSemantics(selectedAction).getSemanticsData();
    expect(selectedData.flagsCollection.isSelected, Tristate.isTrue);

    for (final label in const ['Buscar taller', 'Buscar mecánico']) {
      final action = find.bySemanticsLabel(label);
      final data = tester.getSemantics(action).getSemanticsData();
      expect(data.flagsCollection.isSelected, Tristate.isFalse);
    }
  }, semanticsEnabled: true);

  testWidgets('keeps the last selected home action highlighted on return',
      (tester) async {
    await tester.pumpWidget(subject());

    await tester.tap(find.text('Buscar taller'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    final selectedAction = find.bySemanticsLabel('Buscar taller');
    final decorations = tester
        .widgetList<Container>(
          find.descendant(
            of: selectedAction,
            matching: find.byType(Container),
          ),
        )
        .map((container) => container.decoration)
        .whereType<BoxDecoration>();
    final cardDecoration =
        decorations.firstWhere((decoration) => decoration.boxShadow != null);
    final border = cardDecoration.border! as Border;

    expect(border.top.color, AppColors.primary);
    expect(border.top.width, 2);
    expect(
      tester
          .getSemantics(selectedAction)
          .getSemanticsData()
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
  }, semanticsEnabled: true);

  testWidgets('each consumer action is a button with a 48 dp touch target',
      (tester) async {
    await tester.pumpWidget(subject());

    final semantics = tester.ensureSemantics();
    try {
      for (final label in actionLabels) {
        final action = find.bySemanticsLabel(label);
        expect(action, findsOneWidget);
        final semanticsData = tester.getSemantics(action).getSemanticsData();
        expect(semanticsData.flagsCollection.isButton, isTrue);
        expect(semanticsData.hasAction(SemanticsAction.tap), isTrue);
        expect(
          find.descendant(
            of: action,
            matching: find.byIcon(Icons.chevron_right_rounded),
          ),
          findsNothing,
        );
        expect(tester.getSize(action).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('consumer actions stay equal and overflow-free on phone widths',
      (tester) async {
    final flutterErrors = <FlutterErrorDetails>[];
    final actionSizesByConfiguration = <List<Size>>[];
    final gridWidths = <double>[];
    final labelsThatExceededMaxLines = <String>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = flutterErrors.add;

    try {
      for (final width in <double>[375, 430]) {
        for (final textScale in <double>[1, 1.3, 2]) {
          await tester.pumpWidget(
            subject(width: width, textScale: textScale),
          );
          await tester.pump();

          gridWidths.add(tester.getSize(find.byType(CategoryGrid)).width);
          final actionSizes = <Size>[];
          for (var i = 0; i < actionLabels.length; i++) {
            final action = find.bySemanticsLabel(actionLabels[i]);
            if (action.evaluate().length == 1) {
              actionSizes.add(tester.getSize(action));
            }
            if (textScale == 2) {
              final label = visibleActionLabels[i];
              final textFinder = find.text(label);
              final text = tester.widget<Text>(textFinder);
              final paragraph = tester.renderObject<RenderParagraph>(
                textFinder,
              );
              final painter = TextPainter(
                text: TextSpan(text: label, style: text.style),
                maxLines: text.maxLines,
                textAlign: text.textAlign ?? TextAlign.start,
                textDirection: Directionality.of(tester.element(textFinder)),
                textScaler: MediaQuery.textScalerOf(
                  tester.element(textFinder),
                ),
              )..layout(maxWidth: paragraph.constraints.maxWidth);
              if (painter.didExceedMaxLines) {
                labelsThatExceededMaxLines.add('$width dp: $label');
              }
            }
          }
          actionSizesByConfiguration.add(actionSizes);
        }
      }
    } finally {
      FlutterError.onError = previousOnError;
    }

    expect(
      flutterErrors,
      isEmpty,
      reason:
          flutterErrors.map((error) => error.exceptionAsString()).join('\n'),
    );
    expect(gridWidths, <double>[335, 335, 335, 390, 390, 390]);
    expect(labelsThatExceededMaxLines, isEmpty);
    for (var i = 0; i < actionSizesByConfiguration.length; i++) {
      final actionSizes = actionSizesByConfiguration[i];
      expect(actionSizes, hasLength(3));
      expect(actionSizes.map((size) => size.width).toSet(), hasLength(1));
      if (actionSizes.first.width < gridWidths[i]) {
        expect(actionSizes.map((size) => size.height).toSet(), hasLength(1));
      }
    }
  });

  testWidgets('reduced motion disables press scaling', (tester) async {
    await tester.pumpWidget(subject(disableAnimations: true));

    final action = find.bySemanticsLabel('Buscar taller');
    final animatedScale = find.descendant(
      of: action,
      matching: find.byType(AnimatedScale),
    );
    expect(animatedScale, findsOneWidget);
    expect(tester.widget<AnimatedScale>(animatedScale).duration, Duration.zero);

    final gesture = await tester.startGesture(tester.getCenter(action));
    await tester.pump();

    expect(tester.widget<AnimatedScale>(animatedScale).scale, 1);
    expect(tester.widget<AnimatedScale>(animatedScale).duration, Duration.zero);
    await gesture.cancel();
  });

  testWidgets('spare-parts action passes shared vehicle context to the wizard',
      (tester) async {
    await tester.pumpWidget(
      subject(
        selectedVehicle: fixtureCar,
        selectedVariantId: 'variant-1',
      ),
    );

    await tester.tap(find.text('Pedir repuesto'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final wizard = tester.widget<SparePartWizardPage>(
      find.byType(SparePartWizardPage),
    );
    expect(wizard.initialVehicle, fixtureCar);
    expect(wizard.initialVariantId, 'variant-1');
  });

  testWidgets(
      'each business role can select statistics without unrelated actions',
      (tester) async {
    await tester.pumpWidget(subject(role: UserRole.mechanic));

    expect(find.text('Estadísticas'), findsOneWidget);
    expect(find.text('Pedir repuesto'), findsOneWidget);
    expect(find.text('Buscar taller'), findsOneWidget);
    expect(find.text('Buscar mecánico'), findsNothing);

    await tester.tap(find.text('Estadísticas'));
    await tester.pump();
    var context = tester.element(find.byType(CategoryGrid));
    expect(
      ProviderScope.containerOf(context).read(selectedServiceTypeProvider),
      ServiceType.storeDashboard,
    );

    await tester.pumpWidget(subject(role: UserRole.workshop));
    expect(find.text('Estadísticas'), findsOneWidget);
    expect(find.text('Pedir repuesto'), findsOneWidget);
    expect(find.text('Buscar taller'), findsNothing);
    expect(find.text('Buscar mecánico'), findsOneWidget);

    await tester.pumpWidget(subject(role: UserRole.store));
    expect(find.text('Estadísticas'), findsOneWidget);
    expect(find.text('Pedir repuesto'), findsNothing);
    expect(find.text('Buscar taller'), findsOneWidget);
    expect(find.text('Buscar mecánico'), findsOneWidget);

    await tester.tap(find.text('Estadísticas'));
    await tester.pump();

    context = tester.element(find.byType(CategoryGrid));
    expect(
      ProviderScope.containerOf(context).read(selectedServiceTypeProvider),
      ServiceType.storeDashboard,
    );
  });
}
