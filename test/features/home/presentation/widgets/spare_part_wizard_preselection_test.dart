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

    expect(find.text('Paso 1 de 3'), findsOneWidget);
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
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Paso 2 de 3'), findsOneWidget);
    final state = tester.state(find.byType(SparePartWizardPage)) as dynamic;
    expect(state.debugTemporaryVariantId, 'variant-1');
  });
}
