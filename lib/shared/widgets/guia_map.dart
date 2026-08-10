import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart'; // Adjust path if needed

class GuiaMap extends StatelessWidget {
  final LatLng point;
  final bool isApproximate;
  final Widget? overlay;
  final Key? mapKey;

  const GuiaMap({
    super.key,
    required this.point,
    this.isApproximate = false,
    this.overlay,
    this.mapKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 175,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          FlutterMap(
            key: mapKey,
            options: MapOptions(
              initialCenter: point,
              initialZoom: isApproximate ? 12.0 : 15.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png',
                userAgentPackageName: 'com.guiautomotriz.mobile',
              ),
              if (!isApproximate)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
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
          ),

          // Badge informativo
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                  const Icon(Icons.my_location_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    !isApproximate
                        ? '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}'
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

          if (overlay != null) overlay!,
        ],
      ),
    );
  }
}
