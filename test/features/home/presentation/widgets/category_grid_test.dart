import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/service_type.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/user_role.dart';
import 'package:guiautomotriz_mobile/core/providers/current_user_provider.dart';
import 'package:guiautomotriz_mobile/core/router/route_names.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/navigation/category_grid.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_page.dart';
import 'package:guiautomotriz_mobile/features/vehicles/domain/entities/user_car.dart';
import 'package:guiautomotriz_mobile/features/vehicles/presentation/providers/vehicle_providers.dart';

void main() {
  const actionLabels = <String>[
    'Solicitar repuesto',
    'Buscar talleres',
    'Buscar mecánicos',
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
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(
            body: Align(
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

  testWidgets('consumer actions use direct labels and navigate to providers',
      (tester) async {
    await tester.pumpWidget(subject());

    for (final label in actionLabels) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('Buscar talleres'));
    await tester.pumpAndSettle();
    expect(find.text('workshops-route'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buscar mecánicos'));
    await tester.pumpAndSettle();
    expect(find.text('mechanics-route'), findsOneWidget);
  });

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
          for (final label in actionLabels) {
            final action = find.bySemanticsLabel(label);
            if (action.evaluate().length == 1) {
              actionSizes.add(tester.getSize(action));
            }
            if (textScale == 2) {
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
    for (final actionSizes in actionSizesByConfiguration) {
      expect(actionSizes, hasLength(3));
      expect(actionSizes.map((size) => size.width).toSet(), hasLength(1));
      expect(actionSizes.map((size) => size.height).toSet(), hasLength(1));
    }
  });

  testWidgets('reduced motion disables press scaling', (tester) async {
    await tester.pumpWidget(subject(disableAnimations: true));

    final action = find.bySemanticsLabel('Buscar talleres');
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

    await tester.tap(find.text('Solicitar repuesto'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final wizard = tester.widget<SparePartWizardPage>(
      find.byType(SparePartWizardPage),
    );
    expect(wizard.initialVehicle, fixtureCar);
    expect(wizard.initialVariantId, 'variant-1');
  });

  testWidgets(
      'provider restrictions and store dashboard behavior remain intact',
      (tester) async {
    await tester.pumpWidget(subject(role: UserRole.mechanic));

    expect(find.text('Solicitar repuesto'), findsOneWidget);
    expect(find.text('Buscar talleres'), findsOneWidget);
    expect(find.text('Buscar mecánicos'), findsNothing);

    await tester.pumpWidget(subject(role: UserRole.store));
    expect(find.text('Estadísticas'), findsOneWidget);
    expect(find.text('Solicitar repuesto'), findsNothing);
    expect(find.text('Buscar talleres'), findsOneWidget);
    expect(find.text('Buscar mecánicos'), findsOneWidget);

    await tester.tap(find.text('Estadísticas'));
    await tester.pump();

    final context = tester.element(find.byType(CategoryGrid));
    expect(
      ProviderScope.containerOf(context).read(selectedServiceTypeProvider),
      ServiceType.storeDashboard,
    );
  });
}
