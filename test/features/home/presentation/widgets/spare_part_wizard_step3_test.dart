import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/spare_part_wizard/request_location_selection.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_page.dart';

Widget _testApp({
  required RequestLocationSelection? selection,
  required VoidCallback onSubmit,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SparePartWizardStep3(
        detailsController: TextEditingController(),
        selectedImagePath: null,
        isOtroCategory: false,
        requestLocation: selection,
        onLocationTap: () {},
        onImagePicked: (_) {},
        onSubmit: onSubmit,
      ),
    ),
  );
}

void main() {
  testWidgets('step 3 requires a request-local location', (tester) async {
    await tester.pumpWidget(
      _testApp(selection: null, onSubmit: () {}),
    );

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Enviar solicitud'),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Elige una ubicación para continuar.'), findsOneWidget);
    expect(find.text('Elegir ubicación'), findsOneWidget);
  });

  testWidgets('step 3 submits with a confirmed manual location',
      (tester) async {
    var submits = 0;
    await tester.pumpWidget(
      _testApp(
        selection: const RequestLocationSelection(
          latitude: 10.4806,
          longitude: -66.9036,
          label: 'Sabana Grande, Caracas',
          source: RequestLocationSource.mapTap,
        ),
        onSubmit: () => submits++,
      ),
    );

    await tester.ensureVisible(find.text('Enviar solicitud'));
    await tester.tap(find.text('Enviar solicitud'));

    expect(submits, 1);
    expect(find.text('Sabana Grande, Caracas'), findsOneWidget);
    expect(find.text('Cambiar'), findsOneWidget);
  });
}
