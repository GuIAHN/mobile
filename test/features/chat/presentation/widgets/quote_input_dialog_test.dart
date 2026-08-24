import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/widgets/quote_input_dialog.dart';

void main() {
  Future<Map<String, dynamic>?> openDialog(WidgetTester tester) async {
    Map<String, dynamic>? submitted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                submitted = await QuoteInputDialog.show(
                  context,
                  'Pastillas de freno',
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    return submitted;
  }

  testWidgets('shows only an optional delivery price field', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await openDialog(tester);

    expect(find.text('PRECIO DEL DELIVERY (OPCIONAL)'), findsOneWidget);
    expect(find.text('Incluir delivery'), findsNothing);
    expect(find.byType(SwitchListTile), findsNothing);
    expect(
      find.text(
        'Déjalo vacío si no ofrecerás delivery. Escribe 0 si es gratis.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('remains usable on a small phone with scaled text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.5),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => QuoteInputDialog.show(
                context,
                'Pastillas de freno delanteras',
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('PRECIO DEL DELIVERY (OPCIONAL)'));

    expect(find.text('PRECIO DEL DELIVERY (OPCIONAL)'), findsOneWidget);
  });

  testWidgets('allows submitting with the delivery price empty',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Map<String, dynamic>? submitted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                submitted = await QuoteInputDialog.show(
                  context,
                  'Pastillas de freno',
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '125');
    await tester.pump();
    await tester.ensureVisible(find.text('ENVIAR OFERTA'));
    await tester.tap(find.text('ENVIAR OFERTA'));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!['deliveryCost'], isNull);
    expect(submitted!['updateDeliveryCost'], isTrue);
  });

  testWidgets('submits an entered optional delivery cost', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Map<String, dynamic>? submitted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                submitted = await QuoteInputDialog.show(
                  context,
                  'Pastillas de freno',
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '125');
    await tester.enterText(find.byType(TextField).at(1), '18.50');
    await tester.ensureVisible(find.text('ENVIAR OFERTA'));
    await tester.tap(find.text('ENVIAR OFERTA'));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!['price'], 125);
    expect(submitted!['deliveryCost'], 18.5);
    expect(submitted!['updateDeliveryCost'], isTrue);
  });

  testWidgets('can be dragged down to dismiss without submitting',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Map<String, dynamic>? submitted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                submitted = await QuoteInputDialog.show(
                  context,
                  'Pastillas de freno',
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '125');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();

    final dragHandle = find.byKey(const Key('quote-sheet-drag-handle'));
    await tester.dragFrom(
      tester.getCenter(dragHandle),
      const Offset(0, 760),
    );
    await tester.pumpAndSettle();

    expect(find.byType(QuoteInputDialog), findsNothing);
    expect(submitted, isNull);
  });

  testWidgets('offers an accessible close target as a gesture alternative',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await openDialog(tester);

    final closeButton = find.byKey(const Key('close-quote-sheet'));
    final closeButtonSize = tester.getSize(closeButton);
    expect(closeButtonSize.width, greaterThanOrEqualTo(48));
    expect(closeButtonSize.height, greaterThanOrEqualTo(48));

    await tester.tap(closeButton);
    await tester.pumpAndSettle();

    expect(find.byType(QuoteInputDialog), findsNothing);
  });
}
