import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/widgets/workshop_location_step.dart';
import 'package:guiautomotriz_mobile/shared/widgets/guia_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  const initialLocation = LatLng(14.0818, -87.2068);

  Widget buildSubject({
    required ValueChanged<LatLng> onLocationChanged,
    required ValueChanged<bool> onConfirmedChanged,
    bool confirmed = false,
    Size size = const Size(390, 844),
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size, textScaler: textScaler),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: WorkshopLocationStep(
              location: initialLocation,
              onLocationChanged: onLocationChanged,
              ubicacionConfirmada: confirmed,
              onUbicacionConfirmadaChanged: onConfirmedChanged,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('uses GuiaMap and returns the exact selected coordinates',
      (tester) async {
    LatLng? selectedLocation;
    bool? confirmed;

    await tester.pumpWidget(
      buildSubject(
        onLocationChanged: (value) => selectedLocation = value,
        onConfirmedChanged: (value) => confirmed = value,
      ),
    );

    final map = tester.widget<GuiaMap>(find.byType(GuiaMap));
    expect(map.point, initialLocation);

    const selected = LatLng(15.5039, -88.0047);
    map.onTap!(selected);

    expect(selectedLocation, selected);
    expect(confirmed, isFalse);
  });

  testWidgets('shows a recoverable validation message for an empty search',
      (tester) async {
    await tester.pumpWidget(
      buildSubject(
        onLocationChanged: (_) {},
        onConfirmedChanged: (_) {},
        size: const Size(320, 700),
        textScaler: const TextScaler.linear(1.6),
      ),
    );

    await tester.tap(find.byTooltip('Buscar dirección'));
    await tester.pump();

    expect(find.text('Escribe una dirección para buscarla.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('remains usable on a large phone with scaled text',
      (tester) async {
    await tester.pumpWidget(
      buildSubject(
        onLocationChanged: (_) {},
        onConfirmedChanged: (_) {},
        size: const Size(430, 932),
        textScaler: const TextScaler.linear(2),
      ),
    );

    await tester.ensureVisible(find.text('Confirmar Ubicación'));
    await tester.pump();

    expect(find.byType(GuiaMap), findsOneWidget);
    expect(find.text('Confirmar Ubicación'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
