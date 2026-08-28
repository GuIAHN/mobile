import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/widgets/non_delivery_dialog.dart';

void main() {
  Future<void> openDialog(
    WidgetTester tester, {
    double textScale = 1,
  }) async {
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Builder(builder: (context) {
        return Scaffold(
          body: ElevatedButton(
            onPressed: () => NonDeliveryDialog.show(context),
            child: const Text('Abrir'),
          ),
        );
      }),
    ));

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'mantiene la acción principal en una línea en un teléfono pequeño',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await openDialog(tester);
    await tester.ensureVisible(find.byKey(const Key('confirm-non-delivery')));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.text('Cancelar pedido')).height, lessThan(30));
    expect(tester.takeException(), isNull);
  });

  testWidgets('apila los botones sin aserciones con texto ampliado',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await openDialog(tester, textScale: 1.6);
    await tester.ensureVisible(find.byKey(const Key('confirm-non-delivery')));
    await tester.pumpAndSettle();

    final confirmTop =
        tester.getTopLeft(find.byKey(const Key('confirm-non-delivery'))).dy;
    final backTop =
        tester.getTopLeft(find.widgetWithText(OutlinedButton, 'Volver')).dy;
    expect(confirmTop, lessThan(backTop));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Otro exige y devuelve una razón escrita', (tester) async {
    NonDeliveryResult? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        return Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              result = await NonDeliveryDialog.show(context);
            },
            child: const Text('Abrir'),
          ),
        );
      }),
    ));

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Otro'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('non-delivery-other-reason')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('confirm-non-delivery')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-non-delivery')));
    await tester.pump();
    expect(find.text('Escribe el motivo para continuar.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('non-delivery-other-reason')),
      'El local estará cerrado',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('confirm-non-delivery')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-non-delivery')));
    await tester.pumpAndSettle();

    expect(result?.reasonCode, 'OTRO');
    expect(result?.note, 'El local estará cerrado');
  });
}
