import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_page.dart';
import 'package:guiautomotriz_mobile/features/vehicles/domain/entities/user_car.dart';
import 'package:guiautomotriz_mobile/features/vehicles/presentation/providers/vehicle_providers.dart';

void main() {
  const fixtureCar = UserCar(
    id: 'car-1',
    brand: 'Audi',
    model: '4000',
    year: 1985,
  );

  testWidgets('starts on step 1 with the initial vehicle selected',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userCarsProvider.overrideWith((ref) async => [fixtureCar]),
        ],
        child: const MaterialApp(
          home: SparePartWizardPage(
            initialVehicle: fixtureCar,
            initialVariantId: 'variant-1',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Paso 1 de 3'), findsOneWidget);
    expect(find.text('Audi 4000'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Selecciona la categoría'), findsNothing);
  });

  testWidgets('keeps the initial variant when confirming the temporary car',
      (tester) async {
    const temporaryCar = UserCar(
      id: 'temp-car-1',
      brand: 'Audi',
      model: '4000',
      year: 1985,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userCarsProvider.overrideWith((ref) async => [temporaryCar]),
        ],
        child: const MaterialApp(
          home: SparePartWizardPage(
            initialVehicle: temporaryCar,
            initialVariantId: 'variant-1',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Audi 4000'));
    await tester.pump();
    await tester.ensureVisible(find.text('Continuar'));
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.textContaining('Paso 2 de 3'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is NetworkImage &&
            (widget.image as NetworkImage).url ==
                temporaryCar.computedBrandLogoUrl,
      ),
      findsOneWidget,
    );
    final state = tester.state(find.byType(SparePartWizardPage)) as dynamic;
    expect(state.debugTemporaryVariantId, 'variant-1');
  });

  testWidgets('shows a free-standing brand logo in the step summary',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userCarsProvider.overrideWith((ref) async => [fixtureCar]),
        ],
        child: const MaterialApp(
          home: SparePartWizardPage(initialVehicle: fixtureCar),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Audi 4000'));
    await tester.pump();
    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    final logo = find.byKey(const Key('wizard-summary-brand-logo'));
    expect(logo, findsOneWidget);
    final logoBox = tester.widget<SizedBox>(logo);
    expect(logoBox.width, greaterThan(48));
    expect(logoBox.width, greaterThan(logoBox.height!));
  });

  testWidgets('reports the visible vehicle position while swiping the garage',
      (tester) async {
    const secondCar = UserCar(
      id: 'car-2',
      brand: 'BMW',
      model: '6 Series',
      year: 1984,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userCarsProvider.overrideWith(
            (ref) async => [fixtureCar, secondCar],
          ),
        ],
        child: const MaterialApp(
          home: SparePartWizardPage(initialVehicle: fixtureCar),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Vehículo 1 de 2'), findsOneWidget);
    await tester.fling(
      find.byKey(const PageStorageKey('wizard-vehicle-carousel')),
      const Offset(-650, 0),
      1400,
    );
    await tester.pumpAndSettle();
    expect(find.text('Vehículo 2 de 2'), findsOneWidget);
  });

  testWidgets('uses a smooth 360ms transition and a restrained title change',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userCarsProvider.overrideWith((ref) async => [fixtureCar]),
        ],
        child: const MaterialApp(
          home: SparePartWizardPage(initialVehicle: fixtureCar),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Audi 4000'));
    await tester.pump();
    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pump();

    expect(find.byKey(const Key('wizard-step-title-1')), findsOneWidget);
    expect(find.byKey(const Key('wizard-step-title-2')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 320));
    final state = tester.state(find.byType(SparePartWizardPage)) as dynamic;
    expect(state.debugWizardPage, greaterThan(0));
    expect(state.debugWizardPage, lessThan(1));

    await tester.pumpAndSettle();
    expect(state.debugWizardPage, 1);
    expect(find.byKey(const Key('wizard-step-title-1')), findsNothing);
    expect(find.byKey(const Key('wizard-step-title-2')), findsOneWidget);
  });

  testWidgets('jumps between steps when reduced motion is requested',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userCarsProvider.overrideWith((ref) async => [fixtureCar]),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const SparePartWizardPage(initialVehicle: fixtureCar),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Audi 4000'));
    await tester.pump();
    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pump();

    final state = tester.state(find.byType(SparePartWizardPage)) as dynamic;
    expect(state.debugWizardPage, 1);
    expect(find.byKey(const Key('wizard-step-title-1')), findsNothing);
    expect(find.byKey(const Key('wizard-step-title-2')), findsOneWidget);
  });

  testWidgets('keeps steps 1 and 2 stable across the responsive matrix',
      (tester) async {
    const viewports = [
      Size(320, 667),
      Size(390, 844),
      Size(430, 932),
    ];
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final viewport in viewports) {
      for (final textScale in [1.0, 2.0]) {
        tester.view.physicalSize = viewport;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              userCarsProvider.overrideWith((ref) async => [fixtureCar]),
            ],
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(textScale),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: const SparePartWizardPage(initialVehicle: fixtureCar),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Step 1 overflowed at $viewport and ${textScale}x text',
        );

        await tester.ensureVisible(find.text('Audi 4000'));
        await tester.pump();
        await tester.tap(find.text('Audi 4000'));
        await tester.pump();
        await tester.ensureVisible(find.text('Continuar'));
        await tester.tap(find.text('Continuar'));
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Step 2 overflowed at $viewport and ${textScale}x text',
        );
      }
    }
  });
}
