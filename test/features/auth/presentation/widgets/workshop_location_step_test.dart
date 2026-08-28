import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guiautomotriz_mobile/core/services/location_service.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/widgets/workshop_location_step.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/spare_part_wizard/request_location_preview.dart';
import 'package:latlong2/latlong.dart';

class _FakeLocationService extends LocationService {
  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<Position> getCurrentPosition() async => Position(
        longitude: -87.1921,
        latitude: 14.0723,
        timestamp: DateTime(2026),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

  @override
  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async =>
      'Tegucigalpa';
}

void main() {
  const initialLocation = LatLng(10.4806, -66.9036);

  Widget buildSubject({
    required ValueChanged<LatLng> onLocationChanged,
    required ValueChanged<bool> onConfirmedChanged,
    bool confirmed = false,
    bool autoLocate = false,
    Size size = const Size(390, 844),
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    return ProviderScope(
      overrides: [
        locationServiceProvider.overrideWithValue(_FakeLocationService()),
      ],
      child: MaterialApp(
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
                autoLocate: autoLocate,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('uses the same map preview as the request and has no input',
      (tester) async {
    await tester.pumpWidget(
      buildSubject(
        onLocationChanged: (_) {},
        onConfirmedChanged: (_) {},
      ),
    );

    expect(find.byType(RequestLocationPreview), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('Buscar dirección'), findsNothing);
  });

  testWidgets('loads and exposes the current location on entry',
      (tester) async {
    LatLng? selectedLocation;
    bool? confirmed;

    await tester.pumpWidget(
      buildSubject(
        onLocationChanged: (value) => selectedLocation = value,
        onConfirmedChanged: (value) => confirmed = value,
        autoLocate: true,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(selectedLocation, const LatLng(14.0723, -87.1921));
    expect(confirmed, isFalse);
    expect(find.text('Tegucigalpa'), findsOneWidget);
    expect(find.text('Tu ubicación actual'), findsOneWidget);
  });

  testWidgets('remains usable on a small phone with scaled text',
      (tester) async {
    await tester.pumpWidget(
      buildSubject(
        onLocationChanged: (_) {},
        onConfirmedChanged: (_) {},
        size: const Size(320, 700),
        textScaler: const TextScaler.linear(1.6),
      ),
    );

    await tester.ensureVisible(find.text('Confirmar Ubicación'));
    await tester.pump();

    expect(find.byType(RequestLocationPreview), findsOneWidget);
    expect(find.text('Confirmar Ubicación'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
