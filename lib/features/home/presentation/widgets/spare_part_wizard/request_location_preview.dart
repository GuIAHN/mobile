import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/config/env.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import 'request_location_selection.dart';

class RequestLocationPreview extends StatefulWidget {
  final RequestLocationSelection? selection;
  final VoidCallback onTap;
  final bool isLocating;
  final String? errorMessage;

  const RequestLocationPreview({
    super.key,
    required this.selection,
    required this.onTap,
    this.isLocating = false,
    this.errorMessage,
  });

  @override
  State<RequestLocationPreview> createState() => _RequestLocationPreviewState();
}

class _RequestLocationPreviewState extends State<RequestLocationPreview> {
  bool _mapError = false;
  int _mapRevision = 0;

  @override
  void didUpdateWidget(covariant RequestLocationPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selection?.latitude != widget.selection?.latitude ||
        oldWidget.selection?.longitude != widget.selection?.longitude) {
      _mapError = false;
      _mapRevision++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selection = widget.selection;
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final emptyHeight = 148 + ((textScale - 1) * 64).clamp(0.0, 96.0);
    final selectedHeight = 168 + ((textScale - 1) * 44).clamp(0.0, 72.0);
    final semanticsLabel = widget.isLocating
        ? 'Obteniendo tu ubicación actual'
        : selection == null
            ? widget.errorMessage ?? 'Elegir ubicación para esta solicitud'
            : 'Cambiar ubicación para esta solicitud. Ubicación actual: '
                '${selection.displayLabel}. ${selection.sourceLabel}';

    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Material(
        key: const Key('request-location-preview'),
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: SizedBox(
            height: selection == null ? emptyHeight : selectedHeight,
            child: selection == null
                ? _EmptyMapPreview(
                    isLocating: widget.isLocating,
                    errorMessage: widget.errorMessage,
                  )
                : _buildSelectedMap(context, selection),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedMap(
    BuildContext context,
    RequestLocationSelection selection,
  ) {
    final point = LatLng(selection.latitude, selection.longitude);
    final compactAction = MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(16) > 22;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (!_mapError)
          IgnorePointer(
            child: RepaintBoundary(
              child: FlutterMap(
                key: ValueKey('request-preview-map-$_mapRevision'),
                options: MapOptions(
                  initialCenter: point,
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: Env.cartoBasemapUrl,
                    userAgentPackageName: 'com.guiautomotriz.mobile',
                    retinaMode: RetinaMode.isHighDensity(context),
                    errorTileCallback: (_, __, ___) {
                      if (mounted && !_mapError) {
                        setState(() => _mapError = true);
                      }
                    },
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: point,
                        width: 46,
                        height: 46,
                        child: _PreviewPin(source: selection.source),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        else
          _MapFallback(
            onRetry: () {
              setState(() {
                _mapError = false;
                _mapRevision++;
              });
            },
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.96),
              border: const Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selection.displayLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title.copyWith(fontSize: 14),
                      ),
                      Text(
                        selection.sourceLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.meta,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (!compactAction) ...[
                  Text(
                    'Cambiar',
                    style: AppTypography.label.copyWith(
                      color: AppColors.primaryInk,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyMapPreview extends StatelessWidget {
  final bool isLocating;
  final String? errorMessage;

  const _EmptyMapPreview({
    required this.isLocating,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _MapGridPainter()),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.primaryMuted,
                  shape: BoxShape.circle,
                ),
                child: isLocating
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(
                        AppIcons.account,
                        color: AppColors.primary,
                        size: 26,
                      ),
              ),
              const SizedBox(height: 10),
              Text(
                isLocating
                    ? 'Obteniendo tu ubicación actual…'
                    : errorMessage != null
                        ? 'No pudimos ubicarte'
                        : 'Define dónde necesitas el repuesto',
                textAlign: TextAlign.center,
                style: AppTypography.title,
              ),
              const SizedBox(height: 2),
              Text(
                isLocating
                    ? 'Esto puede tardar unos segundos'
                    : errorMessage ?? 'Elegir ubicación',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label.copyWith(
                  color: AppColors.primaryInk,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewPin extends StatelessWidget {
  final RequestLocationSource source;

  const _PreviewPin({required this.source});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        source == RequestLocationSource.gps
            ? AppIcons.account
            : AppIcons.location,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

class _MapFallback extends StatelessWidget {
  final VoidCallback onRetry;
  const _MapFallback({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.grey100,
      child: Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Recargar mapa'),
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.grey200
      ..strokeWidth = 1;
    for (double x = -40; x < size.width + 40; x += 44) {
      canvas.drawLine(Offset(x, 0), Offset(x + 72, size.height), paint);
    }
    for (double y = 14; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 18), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
