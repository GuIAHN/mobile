import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/spare_part_wizard/spare_parts_availability_dialog.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final size in [
    const Size(320, 568),
    const Size(430, 932),
    const Size(800, 375)
  ]) {
    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets('fits $size with text scale $scale and safe areas',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(scale),
                padding: const EdgeInsets.only(top: 44, bottom: 34),
                disableAnimations: true),
            child: const Scaffold(body: SparePartsAvailabilityDialog()),
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final type in [ElevatedButton, TextButton]) {
          final button = find.byType(type);
          await tester.ensureVisible(button);
          expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
          expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
          expect(tester.takeException(), isNull);
        }
        expect(
            find.text(
                'La opción Pedir repuesto se habilitará el 26 de octubre.'),
            findsOneWidget);
      });
    }
  }

  for (final label in ['CONTINUAR', 'ENTENDIDO']) {
    testWidgets('$label returns the expected navigation result',
        (tester) async {
      bool? result;
      await tester.pumpWidget(MaterialApp(
          home: Builder(
              builder: (context) => Scaffold(
                    body: TextButton(
                        onPressed: () async {
                          result =
                              await SparePartsAvailabilityDialog.show(context);
                        },
                        child: const Text('Abrir')),
                  ))));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.byType(SparePartsAvailabilityDialog), findsNothing);
      expect(result, label == 'CONTINUAR' ? isTrue : isNull);
      expect(tester.takeException(), isNull);
    });
  }
}
