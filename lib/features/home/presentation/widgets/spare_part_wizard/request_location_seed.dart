import 'package:latlong2/latlong.dart';

import 'request_location_selection.dart';

class RequestLocationSeed {
  final RequestLocationSelection? selection;
  final LatLng center;

  const RequestLocationSeed({
    required this.selection,
    required this.center,
  });
}

RequestLocationSeed resolveRequestLocationSeed({
  RequestLocationSelection? requestSelection,
  double? gpsLatitude,
  double? gpsLongitude,
  double? profileLatitude,
  double? profileLongitude,
  LatLng fallback = const LatLng(10.4806, -66.9036),
}) {
  if (requestSelection != null &&
      _isValidCoordinates(
        requestSelection.latitude,
        requestSelection.longitude,
      )) {
    return RequestLocationSeed(
      selection: requestSelection,
      center: LatLng(
        requestSelection.latitude,
        requestSelection.longitude,
      ),
    );
  }

  final gps = _selectionFor(
    gpsLatitude,
    gpsLongitude,
    RequestLocationSource.gps,
  );
  if (gps != null) return _seedFor(gps);

  final profile = _selectionFor(
    profileLatitude,
    profileLongitude,
    RequestLocationSource.profile,
  );
  if (profile != null) return _seedFor(profile);

  return RequestLocationSeed(selection: null, center: fallback);
}

RequestLocationSeed _seedFor(RequestLocationSelection selection) {
  return RequestLocationSeed(
    selection: selection,
    center: LatLng(selection.latitude, selection.longitude),
  );
}

RequestLocationSelection? _selectionFor(
  double? latitude,
  double? longitude,
  RequestLocationSource source,
) {
  if (!_isValidCoordinates(latitude, longitude)) return null;
  return RequestLocationSelection(
    latitude: latitude!,
    longitude: longitude!,
    source: source,
  );
}

bool _isValidCoordinates(double? latitude, double? longitude) {
  return latitude != null &&
      longitude != null &&
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}
