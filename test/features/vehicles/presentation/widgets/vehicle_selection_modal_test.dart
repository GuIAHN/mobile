import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/vehicles/domain/entities/brand.dart';
import 'package:guiautomotriz_mobile/features/vehicles/domain/entities/car_model.dart';
import 'package:guiautomotriz_mobile/features/vehicles/presentation/providers/vehicle_providers.dart';
import 'package:guiautomotriz_mobile/features/vehicles/presentation/widgets/vehicle_selection_modal.dart';

void main() {
  const brand = Brand(
    id: 'brand-1',
    name: 'Toyota',
    brandType: 'JAPONES',
    photoUrl: 'https://example.com/toyota.png',
  );
  const model = CarModel(
    id: 'model-1',
    brandId: 'brand-1',
    name: 'Corolla',
    vehicleType: 'CAR',
  );

  Widget subject(
    ValueChanged<VehicleSelectionResult?> onResult, {
    TargetPlatform platform = TargetPlatform.android,
  }) {
    return ProviderScope(
      overrides: [
        brandModelsProvider.overrideWith((ref, id) async => const [model]),
      ],
      child: MaterialApp(
        theme: ThemeData(platform: platform),
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async => onResult(
              await VehicleSelectionModal.show(context, initialBrand: brand),
            ),
            child: const Text('Abrir selector'),
          ),
        ),
      ),
    );
  }

  Future<void> openDetails(WidgetTester tester) async {
    await tester.tap(find.text('Abrir selector'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Corolla'));
    await tester.pumpAndSettle();
  }

  testWidgets('collects wheel year and optional motor without variants',
      (tester) async {
    VehicleSelectionResult? result;
    await tester.pumpWidget(subject((value) => result = value));
    await openDetails(tester);

    expect(find.text('Completa tu vehículo'), findsOneWidget);
    expect(find.byKey(const ValueKey('vehicle-year-wheel')), findsOneWidget);
    expect(find.byKey(const ValueKey('vehicle-motor-input')), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('vehicle-year-wheel')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('vehicle-motor-input')),
      ' 1.8L ',
    );
    final confirm = find.byKey(const ValueKey('confirm-vehicle-details'));
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(result?.modelId, 'model-1');
    expect(result?.year, lessThan(DateTime.now().year));
    expect(result?.motor, '1.8L');
  });

  testWidgets('wheel constrains years to the supported backend range',
      (tester) async {
    await tester.pumpWidget(subject((_) {}));
    await openDetails(tester);
    expect(find.byKey(const ValueKey('vehicle-year-wheel')), findsOneWidget);
    expect(find.byKey(const ValueKey('vehicle-year-1949')), findsNothing);
  });

  testWidgets('keeps accessible 48 dp modal actions', (tester) async {
    await tester.pumpWidget(subject((_) {}));
    await openDetails(tester);
    expect(tester.getSize(find.byTooltip('Volver')).shortestSide, 48);
    expect(tester.getSize(find.byTooltip('Cerrar selector')).shortestSide, 48);
  });

  testWidgets('dismisses the keyboard when tapping outside an input',
      (tester) async {
    await tester.pumpWidget(subject((_) {}));
    await openDetails(tester);
    await tester.tap(find.byKey(const ValueKey('vehicle-motor-input')));
    await tester.pump();

    await tester.tap(find.text('Completa tu vehículo'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('fits small and large phones without layout overflow',
      (tester) async {
    for (final size in <Size>[
      const Size(320, 568),
      const Size(430, 932),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(subject((_) {}));
      await openDetails(tester);

      expect(find.byKey(const ValueKey('vehicle-year-wheel')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('reserves keyboard clearance for the motor field',
      (tester) async {
    await tester.pumpWidget(subject((_) {}));
    await openDetails(tester);
    final motor = find.byKey(const ValueKey('vehicle-motor-input'));
    final field = tester.widget<TextField>(motor);
    final scroll = tester.widget<SingleChildScrollView>(
      find.byKey(const ValueKey('vehicle-details')),
    );

    expect(field.scrollPadding.bottom, 200);
    expect(
      scroll.keyboardDismissBehavior,
      ScrollViewKeyboardDismissBehavior.onDrag,
    );
  });

  testWidgets('uses additional motor-field clearance on iOS', (tester) async {
    await tester.pumpWidget(subject((_) {}, platform: TargetPlatform.iOS));
    await openDetails(tester);
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('vehicle-motor-input')),
    );

    expect(field.scrollPadding.bottom, 320);
  });
}
