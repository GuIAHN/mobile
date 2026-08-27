import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/spare_part_wizard/request_location_preview.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/spare_part_wizard/request_location_selection.dart';

Widget _testApp(Widget child, {double textScale = 1}) {
  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: Scaffold(
      body: Center(
        child: SizedBox(width: 380, child: child),
      ),
    ),
  );
}

void main() {
  testWidgets('the empty card invites selection and is touch friendly',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _testApp(
        RequestLocationPreview(
          selection: null,
          onTap: () => taps++,
        ),
      ),
    );

    final card = find.byKey(const Key('request-location-preview'));
    expect(find.text('Elegir ubicación'), findsOneWidget);
    expect(tester.getSize(card).height, greaterThanOrEqualTo(96));
    expect(
      find.bySemanticsLabel('Elegir ubicación para esta solicitud'),
      findsOneWidget,
    );

    await tester.tap(card);
    expect(taps, 1);
  }, semanticsEnabled: true);

  testWidgets('the selected card shows its label and change action',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        RequestLocationPreview(
          selection: const RequestLocationSelection(
            latitude: 10.4806,
            longitude: -66.9036,
            label: 'Sabana Grande, Caracas',
            source: RequestLocationSource.mapTap,
          ),
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Sabana Grande, Caracas'), findsOneWidget);
    expect(find.text('Cambiar'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Cambiar ubicación para esta solicitud. '
        'Ubicación actual: Sabana Grande, Caracas. '
        'Punto elegido en el mapa',
      ),
      findsOneWidget,
    );
  }, semanticsEnabled: true);

  testWidgets('shows that the current location is being obtained',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        RequestLocationPreview(
          selection: null,
          isLocating: true,
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Obteniendo tu ubicación actual…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      find.bySemanticsLabel('Obteniendo tu ubicación actual'),
      findsOneWidget,
    );
  }, semanticsEnabled: true);

  testWidgets('keeps manual map selection available after a GPS failure',
      (tester) async {
    const message =
        'No pudimos obtener tu ubicación actual. Puedes elegirla en el mapa.';
    await tester.pumpWidget(
      _testApp(
        RequestLocationPreview(
          selection: null,
          errorMessage: message,
          onTap: () {},
        ),
      ),
    );

    expect(find.text('No pudimos ubicarte'), findsOneWidget);
    expect(find.text(message), findsOneWidget);
  });

  testWidgets('identifies a location restored from the saved profile',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        RequestLocationPreview(
          selection: const RequestLocationSelection(
            latitude: 14.0723,
            longitude: -87.1921,
            source: RequestLocationSource.profile,
          ),
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Última ubicación guardada'), findsOneWidget);
    expect(find.text('14.0723, -87.1921'), findsOneWidget);
  });

  testWidgets('the card supports a small phone and enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        RequestLocationPreview(
          selection: const RequestLocationSelection(
            latitude: 10.4806,
            longitude: -66.9036,
            label: 'Sabana Grande, Caracas, Distrito Capital',
            source: RequestLocationSource.mapTap,
          ),
          onTap: () {},
        ),
        textScale: 2,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const Key('request-location-preview'))).height,
      greaterThanOrEqualTo(96),
    );
  });
}
