import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/spare_part_wizard/request_location_seed.dart';
import 'package:guiautomotriz_mobile/shared/location/domain/entities/request_location_selection.dart';
import 'package:latlong2/latlong.dart';

void main() {
  const request = RequestLocationSelection(
    latitude: 9.93,
    longitude: -84.08,
    source: RequestLocationSource.mapTap,
  );

  test('keeps the request-local selection above every other source', () {
    final seed = resolveRequestLocationSeed(
      requestSelection: request,
      gpsLatitude: 10.4806,
      gpsLongitude: -66.9036,
      profileLatitude: 14.0723,
      profileLongitude: -87.1921,
    );

    expect(seed.selection, same(request));
    expect(seed.center, const LatLng(9.93, -84.08));
  });

  test('uses active GPS above the saved profile location', () {
    final seed = resolveRequestLocationSeed(
      gpsLatitude: 10.4806,
      gpsLongitude: -66.9036,
      profileLatitude: 14.0723,
      profileLongitude: -87.1921,
    );

    expect(seed.selection?.source, RequestLocationSource.gps);
    expect(seed.center, const LatLng(10.4806, -66.9036));
  });

  test('uses the saved profile location when GPS is unavailable', () {
    final seed = resolveRequestLocationSeed(
      profileLatitude: 14.0723,
      profileLongitude: -87.1921,
    );

    expect(seed.selection?.source, RequestLocationSource.profile);
    expect(seed.center, const LatLng(14.0723, -87.1921));
  });

  test('rejects incomplete, non-finite, and out-of-range coordinates', () {
    const fallback = LatLng(14.0723, -87.1921);
    final cases = <({double? latitude, double? longitude})>[
      (latitude: 10, longitude: null),
      (latitude: double.nan, longitude: -66),
      (latitude: 91, longitude: -66),
      (latitude: 10, longitude: 181),
    ];

    for (final item in cases) {
      final seed = resolveRequestLocationSeed(
        profileLatitude: item.latitude,
        profileLongitude: item.longitude,
      );
      expect(seed.selection, isNull);
      expect(seed.center, fallback);
    }
  });
}
