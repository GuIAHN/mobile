import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/widgets/non_delivery_dialog.dart';

void main() {
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
