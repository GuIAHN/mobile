import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/spare_part_wizard/request_location_selection.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_page.dart';

Widget _testApp({
  required RequestLocationSelection? selection,
  TextEditingController? detailsController,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SparePartWizardStep3(
        detailsController: detailsController ?? TextEditingController(),
        selectedImagePath: null,
        isOtroCategory: false,
        requestLocation: selection,
        onLocationTap: () {},
        onImagePicked: (_) {},
      ),
    ),
  );
}

void main() {
  testWidgets('step 3 requires a request-local location', (tester) async {
    await tester.pumpWidget(
      _testApp(selection: null),
    );

    expect(find.text('Requerido'), findsNWidgets(2));
    expect(
      find.text(
          'Incluye ubicación, medidas, versión o cualquier detalle útil.'),
      findsOneWidget,
    );
    expect(
      find.text('Define dónde necesitas el repuesto'),
      findsOneWidget,
    );
    expect(find.text('Elegir ubicación'), findsOneWidget);
  });

  testWidgets('step 3 keeps details and a confirmed manual location visible',
      (tester) async {
    final controller = TextEditingController(text: 'Con sensor, lado derecho');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _testApp(
        detailsController: controller,
        selection: const RequestLocationSelection(
          latitude: 10.4806,
          longitude: -66.9036,
          label: 'Sabana Grande, Caracas',
          source: RequestLocationSource.mapTap,
        ),
      ),
    );

    expect(find.text('Con sensor, lado derecho'), findsOneWidget);
    expect(find.text('Sabana Grande, Caracas'), findsOneWidget);
    expect(find.text('Cambiar'), findsOneWidget);
  });
}
