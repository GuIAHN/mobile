import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guiautomotriz_mobile/core/services/location_service.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/spare_part_wizard/request_location_picker_dialog.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/spare_part_wizard/request_location_selection.dart';
import 'package:latlong2/latlong.dart';

class _FakeLocationService extends LocationService {
  _FakeLocationService({this.address});

  final String? address;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<Position> getCurrentPosition() async => Position(
        longitude: -66.9036,
        latitude: 10.4806,
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
      address;
}

Widget _testApp({
  required ValueChanged<RequestLocationSelection?> onResult,
  RequestLocationSelection? initialSelection,
  LocationService? locationService,
}) {
  return ProviderScope(
    overrides: [
      locationServiceProvider.overrideWithValue(
        locationService ?? _FakeLocationService(),
      ),
    ],
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const Key('open-location-picker'),
              onPressed: () async {
                final result = await showDialog<RequestLocationSelection>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => RequestLocationPickerDialog(
                    initialCenter: const LatLng(10.4806, -66.9036),
                    initialSelection: initialSelection,
                    mapBuilder: (context, selection, onMapTap) =>
                        GestureDetector(
                      key: const Key('fake-location-map'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onMapTap(
                        const LatLng(10.5001, -66.9002),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                );
                onResult(result);
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a map tap updates the draft returned by confirmation',
      (tester) async {
    RequestLocationSelection? result;
    await tester.pumpWidget(_testApp(onResult: (value) => result = value));

    await tester.tap(find.byKey(const Key('open-location-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fake-location-map')));
    await tester.pumpAndSettle();

    expect(find.text('10.5001, -66.9002'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-request-location')));
    await tester.pumpAndSettle();

    expect(result?.latitude, 10.5001);
    expect(result?.longitude, -66.9002);
    expect(result?.source, RequestLocationSource.mapTap);
  });

  testWidgets('closing the dialog discards its draft', (tester) async {
    RequestLocationSelection? result;
    var completed = false;
    await tester.pumpWidget(
      _testApp(
        initialSelection: const RequestLocationSelection(
          latitude: 10.4,
          longitude: -66.9,
          source: RequestLocationSource.mapTap,
        ),
        onResult: (value) {
          completed = true;
          result = value;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('open-location-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fake-location-map')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('close-request-location')));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(result, isNull);
  });

  testWidgets('the current-location action returns a GPS selection',
      (tester) async {
    RequestLocationSelection? result;
    await tester.pumpWidget(
      _testApp(
        locationService: _FakeLocationService(
          address: 'Sabana Grande, Caracas',
        ),
        onResult: (value) => result = value,
      ),
    );

    await tester.tap(find.byKey(const Key('open-location-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('use-current-request-location')));
    await tester.pumpAndSettle();

    expect(find.text('Sabana Grande, Caracas'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-request-location')));
    await tester.pumpAndSettle();

    expect(result?.source, RequestLocationSource.gps);
    expect(result?.latitude, 10.4806);
    expect(result?.longitude, -66.9036);
  });
}
