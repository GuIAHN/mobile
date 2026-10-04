import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google;
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import 'guia_google_map.dart';

class GuiaMap extends StatefulWidget {
  final LatLng point;
  final bool isApproximate;
  final Widget? overlay;
  final Key? mapKey;
  final double height;
  final double borderRadius;
  final bool interactive;
  final ValueChanged<LatLng>? onTap;
  final EdgeInsets mapPadding;
  final bool showCoordinateLabel;

  const GuiaMap({
    super.key,
    required this.point,
    this.isApproximate = false,
    this.overlay,
    this.mapKey,
    this.height = 175,
    this.borderRadius = 16,
    this.interactive = true,
    this.onTap,
    this.mapPadding = EdgeInsets.zero,
    this.showCoordinateLabel = true,
  });

  @override
  State<GuiaMap> createState() => _GuiaMapState();
}

class _GuiaMapState extends State<GuiaMap> {
  google.GoogleMapController? _controller;
  Timer? _readinessTimer;
  bool _isReady = false;
  bool _mapError = false;
  int _mapRevision = 0;

  @override
  void initState() {
    super.initState();
    _startReadinessTimer();
  }

  @override
  void didUpdateWidget(covariant GuiaMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.point != widget.point) {
      _controller?.animateCamera(
        google.CameraUpdate.newLatLng(_googlePoint(widget.point)),
      );
      if (_mapError) _retryMap();
    }
  }

  @override
  void dispose() {
    _readinessTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  google.LatLng _googlePoint(LatLng point) =>
      google.LatLng(point.latitude, point.longitude);

  void _startReadinessTimer() {
    _readinessTimer?.cancel();
    _readinessTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && !_isReady) setState(() => _mapError = true);
    });
  }

  void _handleMapCreated(google.GoogleMapController controller) {
    _controller?.dispose();
    _controller = controller;
    _readinessTimer?.cancel();
    if (mounted) {
      setState(() {
        _isReady = true;
        _mapError = false;
      });
    }
  }

  void _retryMap() {
    _controller?.dispose();
    _controller = null;
    setState(() {
      _mapError = false;
      _isReady = false;
      _mapRevision++;
    });
    _startReadinessTimer();
  }

  @override
  Widget build(BuildContext context) {
    final semanticsLabel = widget.onTap == null
        ? 'Mapa de la ubicación'
        : 'Mapa interactivo. Toca un punto para elegir la ubicación.';
    final target = _googlePoint(widget.point);

    return Semantics(
      container: true,
      label: semanticsLabel,
      value: widget.isApproximate
          ? 'Ubicación aproximada'
          : '${widget.point.latitude.toStringAsFixed(4)}, '
              '${widget.point.longitude.toStringAsFixed(4)}',
      child: Container(
        height: widget.height,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          children: [
            if (!_mapError)
              GuiaGoogleMap(
                key: ValueKey('${widget.mapKey ?? 'guia-map'}-$_mapRevision'),
                initialCenter: widget.point,
                initialZoom: widget.isApproximate ? 12 : 15,
                onMapCreated: _handleMapCreated,
                onTap: widget.onTap,
                padding: widget.mapPadding,
                markers: widget.isApproximate || !widget.interactive
                    ? const <google.Marker>{}
                    : {
                        google.Marker(
                          markerId: const google.MarkerId('selected-location'),
                          position: target,
                          icon: google.BitmapDescriptor.defaultMarkerWithHue(
                            google.BitmapDescriptor.hueOrange,
                          ),
                        ),
                      },
                interactive: widget.interactive,
              )
            else
              _MapErrorState(onRetry: _retryMap),
            if (!_mapError && !widget.isApproximate && !widget.interactive)
              const Positioned.fill(
                child: IgnorePointer(
                  child: Center(child: _BrandedMapMarker()),
                ),
              ),
            if (!_mapError && !_isReady)
              const ColoredBox(
                color: AppColors.grey100,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            if (!_mapError && _isReady && widget.showCoordinateLabel)
              Positioned(
                bottom: 28,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.my_location_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.isApproximate
                            ? 'Ubicación aproximada'
                            : '${widget.point.latitude.toStringAsFixed(4)}, '
                                '${widget.point.longitude.toStringAsFixed(4)}',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (widget.overlay != null) widget.overlay!,
          ],
        ),
      ),
    );
  }
}

class _BrandedMapMarker extends StatelessWidget {
  const _BrandedMapMarker();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        key: const Key('guia-map-branded-marker'),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surface, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const AppLineIcon(
          AppIcons.location,
          size: AppIconSize.leading,
          color: AppColors.surface,
        ),
      ),
    );
  }
}

class _MapErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _MapErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.grey100,
      child: Center(
        child: Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.map_outlined,
                  size: 32,
                  color: AppColors.errorInk,
                ),
                const SizedBox(height: 8),
                Text(
                  'No pudimos cargar el mapa.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryInk,
                    minimumSize: const Size(48, 48),
                  ),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
