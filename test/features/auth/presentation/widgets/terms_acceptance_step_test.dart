import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/theme/app_theme.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/widgets/terms_acceptance_step.dart';

void main() {
  Widget buildApp(
    Widget child, {
    double textScale = 1,
    bool disableAnimations = false,
  }) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: child,
      ),
    );
  }

  testWidgets('shows loading and then renders the legal document',
      (tester) async {
    final completer = Completer<String>();

    await tester.pumpWidget(
      buildApp(
        TermsDocumentViewerPage(
          audience: TermsAudience.consumer,
          assetLoader: (_) => completer.future,
        ),
      ),
    );

    expect(find.text('Cargando documento…'), findsOneWidget);

    completer.complete(
      'TÉRMINOS PARA USUARIOS\n1. PARTES Y ACEPTACIÓN\nContenido legal.',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('terms-document-content')), findsOneWidget);
    expect(find.text('1. PARTES Y ACEPTACIÓN'), findsOneWidget);
    expect(find.byKey(const Key('viewer-accept-checkbox')), findsOneWidget);
  });

  testWidgets('offers recovery when the document cannot be loaded',
      (tester) async {
    var attempts = 0;

    await tester.pumpWidget(
      buildApp(
        TermsDocumentViewerPage(
          audience: TermsAudience.serviceProvider,
          assetLoader: (_) {
            attempts++;
            if (attempts == 1) return Future<String>.error('asset error');
            return Future.value('TÉRMINOS PARA PRESTADORES\nContenido legal.');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No pudimos abrir este documento.'), findsOneWidget);
    expect(find.text('Intentar de nuevo'), findsOneWidget);

    await tester.tap(find.text('Intentar de nuevo'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('terms-document-content')), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets('shows a distinct empty-document state', (tester) async {
    await tester.pumpWidget(
      buildApp(
        TermsDocumentViewerPage(
          audience: TermsAudience.consumer,
          assetLoader: (_) => Future.value('   '),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('El documento está vacío o no está disponible.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('accept-terms-button')), findsNothing);
  });

  testWidgets('requires explicit confirmation and fits a small scaled screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildApp(
        TermsDocumentViewerPage(
          audience: TermsAudience.consumer,
          assetLoader: (_) => Future.value(
            'TÉRMINOS PARA USUARIOS\n1. PARTES Y ACEPTACIÓN\nContenido legal.',
          ),
        ),
        textScale: 1.6,
      ),
    );
    await tester.pumpAndSettle();

    var acceptButton = tester.widget<ElevatedButton>(
      find.byKey(const Key('accept-terms-button')),
    );
    expect(acceptButton.onPressed, isNull);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('viewer-accept-checkbox')));
    await tester.pump();

    acceptButton = tester.widget<ElevatedButton>(
      find.byKey(const Key('accept-terms-button')),
    );
    expect(acceptButton.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the consumer file and returns its accepted state',
      (tester) async {
    var accepted = false;

    await tester.pumpWidget(
      buildApp(
        Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: TermsAcceptanceStep(
                  audience: TermsAudience.consumer,
                  isAccepted: accepted,
                  onAcceptedChanged: (value) {
                    setState(() => accepted = value);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Términos para usuarios'), findsOneWidget);
    expect(accepted, isFalse);

    await tester.tap(find.text('Abrir documento'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('TÉRMINOS Y CONDICIONES DEL SERVICIO'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('viewer-accept-checkbox')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('accept-terms-button')));
    await tester.pumpAndSettle();

    expect(accepted, isTrue);
    expect(find.text('Términos y condiciones aceptados'), findsOneWidget);
  });

  testWidgets('loads the provider file on a large phone with reduced motion',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildApp(
        const TermsDocumentViewerPage(
          audience: TermsAudience.serviceProvider,
        ),
        textScale: 1.3,
        disableAnimations: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Términos para prestadores'), findsOneWidget);
    expect(
      find.textContaining('Prestadores de Servicios'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('terms-document-content')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
