import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/widgets/provider_documents_step.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  testWidgets('el flujo de negocio solicita únicamente el RIF', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in [const Size(320, 568), const Size(430, 932)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: const TextScaler.linear(1.6),
              disableAnimations: true,
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: ProviderDocumentsStep(
                  onRifPhotoChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('RIF'), findsOneWidget);
      expect(find.text('Registro mercantil'), findsNothing);
      expect(
        find.bySemanticsLabel(
          RegExp(r'RIF\s+pendiente\. Toca para adjuntarlo\.'),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('muestra el estado seleccionado del RIF', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderDocumentsStep(
            rifPhoto: XFile('/tmp/rif.jpg'),
            onRifPhotoChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('rif.jpg'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp(r'RIF\s+seleccionado\. Toca para reemplazarlo\.'),
      ),
      findsOneWidget,
    );
  });
}
