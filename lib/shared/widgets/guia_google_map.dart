import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google;
import 'package:latlong2/latlong.dart';

/// Shared Google Maps surface for every map experience in the application.
class GuiaGoogleMap extends StatelessWidget {
  final LatLng initialCenter;
  final double initialZoom;
  final Set<google.Marker> markers;
  final EdgeInsets padding;
  final bool interactive;
  final ValueChanged<google.GoogleMapController>? onMapCreated;
  final ValueChanged<LatLng>? onTap;
  final VoidCallback? onCameraMoveStarted;
  final ValueChanged<LatLng>? onCameraMove;
  final VoidCallback? onCameraIdle;

  const GuiaGoogleMap({
    super.key,
    required this.initialCenter,
    required this.initialZoom,
    this.markers = const <google.Marker>{},
    this.padding = EdgeInsets.zero,
    this.interactive = true,
    this.onMapCreated,
    this.onTap,
    this.onCameraMoveStarted,
    this.onCameraMove,
    this.onCameraIdle,
  });

  @override
  Widget build(BuildContext context) {
    return google.GoogleMap(
      initialCameraPosition: google.CameraPosition(
        target: google.LatLng(
          initialCenter.latitude,
          initialCenter.longitude,
        ),
        zoom: initialZoom,
      ),
      markers: markers,
      padding: padding,
      onMapCreated: onMapCreated,
      onTap: onTap == null
          ? null
          : (point) => onTap!(LatLng(point.latitude, point.longitude)),
      onCameraMoveStarted: onCameraMoveStarted,
      onCameraMove: onCameraMove == null
          ? null
          : (position) => onCameraMove!(
                LatLng(
                  position.target.latitude,
                  position.target.longitude,
                ),
              ),
      onCameraIdle: onCameraIdle,
      compassEnabled: false,
      mapToolbarEnabled: false,
      myLocationButtonEnabled: false,
      rotateGesturesEnabled: false,
      scrollGesturesEnabled: interactive,
      tiltGesturesEnabled: false,
      zoomControlsEnabled: false,
      zoomGesturesEnabled: interactive,
    );
  }
}
