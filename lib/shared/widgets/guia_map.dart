import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/config/env.dart';
import '../../core/theme/app_colors.dart';

class GuiaMap extends StatefulWidget {
  final LatLng point;
  final bool isApproximate;
  final Widget? overlay;
  final Key? mapKey;
  final double height;
  final double borderRadius;
  final bool interactive;
  final ValueChanged<LatLng>? onTap;

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
  });

  @override
  State<GuiaMap> createState() => _GuiaMapState();
}

class _GuiaMapState extends State<GuiaMap> {
  bool _mapError = false;
  int _mapRevision = 0;

  @override
  void didUpdateWidget(covariant GuiaMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.point != widget.point && _mapError) {
      _mapError = false;
      _mapRevision++;
    }
  }

  void _handleMapError() {
    if (!mounted || _mapError) return;
    setState(() => _mapError = true);
  }

  void _retryMap() {
    setState(() {
      _mapError = false;
      _mapRevision++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final semanticsLabel = widget.onTap == null
        ? 'Mapa de la ubicación'
        : 'Mapa interactivo. Toca un punto para elegir la ubicación.';

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
              FlutterMap(
                key: ValueKey('${widget.mapKey ?? 'guia-map'}-$_mapRevision'),
                options: MapOptions(
                  initialCenter: widget.point,
                  initialZoom: widget.isApproximate ? 12.0 : 15.0,
                  interactionOptions: InteractionOptions(
                    flags: widget.interactive
                        ? InteractiveFlag.drag | InteractiveFlag.pinchZoom
                        : InteractiveFlag.none,
                  ),
                  onTap: widget.onTap == null
                      ? null
                      : (_, point) => widget.onTap!(point),
                ),
                children: [
                  TileLayer(
                    urlTemplate: Env.cartoBasemapUrl,
                    userAgentPackageName: 'com.guiautomotriz.mobile',
                    retinaMode: RetinaMode.isHighDensity(context),
                    errorTileCallback: (_, __, ___) => _handleMapError(),
                  ),
                  if (!widget.isApproximate)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: widget.point,
                          width: 44,
                          height: 44,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.near_me_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              )
            else
              _MapErrorState(onRetry: _retryMap),
            if (!_mapError)
              Positioned(
                bottom: 10,
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
                        !widget.isApproximate
                            ? '${widget.point.latitude.toStringAsFixed(4)}, '
                                '${widget.point.longitude.toStringAsFixed(4)}'
                            : 'Ubicación aproximada',
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
