import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/services/location_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import 'request_location_selection.dart';

typedef RequestLocationMapBuilder = Widget Function(
  BuildContext context,
  RequestLocationSelection? selection,
  ValueChanged<LatLng> onMapTap,
  VoidCallback onMapError,
);

class RequestLocationPickerDialog extends ConsumerStatefulWidget {
  final RequestLocationSelection? initialSelection;
  final LatLng initialCenter;
  final RequestLocationMapBuilder? mapBuilder;

  const RequestLocationPickerDialog({
    super.key,
    required this.initialCenter,
    this.initialSelection,
    this.mapBuilder,
  });

  static Future<RequestLocationSelection?> show(
    BuildContext context, {
    required LatLng initialCenter,
    RequestLocationSelection? initialSelection,
  }) {
    return showDialog<RequestLocationSelection>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RequestLocationPickerDialog(
        initialCenter: initialCenter,
        initialSelection: initialSelection,
      ),
    );
  }

  @override
  ConsumerState<RequestLocationPickerDialog> createState() =>
      _RequestLocationPickerDialogState();
}

class _RequestLocationPickerDialogState
    extends ConsumerState<RequestLocationPickerDialog> {
  final MapController _mapController = MapController();
  final StreamController<void> _tileResetController =
      StreamController<void>.broadcast();
  RequestLocationSelection? _draft;
  bool _isLocating = false;
  bool _mapError = false;
  String? _locationError;
  int _selectionRevision = 0;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialSelection;
  }

  @override
  void dispose() {
    _tileResetController.close();
    _mapController.dispose();
    super.dispose();
  }

  void _handleMapError() {
    if (!mounted || _mapError) return;
    setState(() => _mapError = true);
  }

  void _retryMap() {
    setState(() => _mapError = false);
    if (widget.mapBuilder == null) {
      _tileResetController.add(null);
    }
  }

  Future<void> _selectPoint(
    LatLng point,
    RequestLocationSource source,
  ) async {
    final revision = ++_selectionRevision;
    final selection = RequestLocationSelection(
      latitude: point.latitude,
      longitude: point.longitude,
      source: source,
    );
    setState(() {
      _draft = selection;
      _locationError = null;
    });

    final label =
        await ref.read(locationServiceProvider).getAddressFromCoordinates(
              point.latitude,
              point.longitude,
            );
    if (!mounted || revision != _selectionRevision) return;

    final current = _draft;
    if (current == null ||
        current.latitude != point.latitude ||
        current.longitude != point.longitude) {
      return;
    }
    setState(() {
      _draft = RequestLocationSelection(
        latitude: point.latitude,
        longitude: point.longitude,
        label: label,
        source: source,
      );
    });
  }

  Future<void> _useCurrentLocation() async {
    if (_isLocating) return;
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    final service = ref.read(locationServiceProvider);
    try {
      if (!await service.isLocationServiceEnabled()) {
        throw const _LocationPickerException(
          'Activa el servicio de ubicación para usar tu posición actual.',
        );
      }

      var permission = await service.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await service.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const _LocationPickerException(
          'No pudimos acceder al GPS. Puedes elegir un punto en el mapa.',
        );
      }

      final position = await service.getCurrentPosition();
      final point = LatLng(position.latitude, position.longitude);
      if (widget.mapBuilder == null) {
        _mapController.move(point, 16);
      }
      await _selectPoint(point, RequestLocationSource.gps);
    } on _LocationPickerException catch (error) {
      if (mounted) setState(() => _locationError = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationError =
              'No pudimos obtener tu ubicación. Intenta nuevamente o toca el mapa.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Widget _buildMap(BuildContext context) {
    final customBuilder = widget.mapBuilder;
    if (customBuilder != null) {
      return customBuilder(
        context,
        _draft,
        (point) => _selectPoint(point, RequestLocationSource.mapTap),
        _handleMapError,
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.initialCenter,
        initialZoom: _draft == null ? 12 : 15,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
        ),
        onTap: (_, point) {
          _selectPoint(point, RequestLocationSource.mapTap);
        },
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png',
          userAgentPackageName: 'com.guiautomotriz.mobile',
          reset: _tileResetController.stream,
          errorTileCallback: (_, __, ___) => _handleMapError(),
        ),
        if (_draft != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(_draft!.latitude, _draft!.longitude),
                width: 52,
                height: 52,
                child: Semantics(
                  label: 'Ubicación seleccionada: ${_draft!.displayLabel}',
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final selection = _draft;
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: _buildMap(context)),
              if (_mapError)
                Positioned(
                  top: 88,
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  child: Semantics(
                    container: true,
                    liveRegion: true,
                    label:
                        'No pudimos cargar el mapa. Reintentar carga del mapa.',
                    excludeSemantics: true,
                    child: Material(
                      color: AppColors.surface,
                      elevation: 2,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.lg,
                          right: AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.map_outlined,
                              color: AppColors.errorInk,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'No pudimos cargar el mapa.',
                                style: AppTypography.bodySm,
                              ),
                            ),
                            TextButton(
                              key: const Key('retry-request-location-map'),
                              onPressed: _retryMap,
                              style: TextButton.styleFrom(
                                minimumSize: const Size(48, 48),
                              ),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: AppSpacing.md,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                child: Material(
                  color: AppColors.surface,
                  elevation: 2,
                  shadowColor: Colors.black.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  child: SizedBox(
                    height: 56,
                    child: Row(
                      children: [
                        Semantics(
                          button: true,
                          label: 'Cerrar selector de ubicación',
                          excludeSemantics: true,
                          child: IconButton(
                            key: const Key('close-request-location'),
                            onPressed: () => Navigator.pop(context),
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Elegir ubicación',
                            textAlign: TextAlign.center,
                            style: AppTypography.title,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: AppSpacing.lg,
                bottom: 190,
                child: Semantics(
                  button: true,
                  label: 'Usar mi ubicación actual',
                  excludeSemantics: true,
                  child: FloatingActionButton.small(
                    key: const Key('use-current-request-location'),
                    onPressed: _isLocating ? null : _useCurrentLocation,
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.primary,
                    elevation: 3,
                    child: _isLocating
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(Icons.my_location_rounded),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 172),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl2,
                    AppSpacing.xl,
                    AppSpacing.xl2,
                    AppSpacing.lg,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('UBICACIÓN SELECCIONADA',
                            style: AppTypography.overline),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          selection?.displayLabel ??
                              'Toca el mapa para colocar el marcador.',
                          style: AppTypography.body.copyWith(
                            color: selection == null
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (_locationError != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _locationError!,
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.errorInk,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          height: AppSpacing.buttonHeightLg,
                          child: ElevatedButton(
                            key: const Key('confirm-request-location'),
                            onPressed: selection == null
                                ? null
                                : () => Navigator.pop(context, selection),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textOnPrimary,
                              disabledBackgroundColor:
                                  AppColors.disabledBackground,
                              disabledForegroundColor: AppColors.disabledText,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull,
                                ),
                              ),
                            ),
                            child: Text(
                              'Usar esta ubicación',
                              style: AppTypography.label.copyWith(
                                color: selection == null
                                    ? AppColors.disabledText
                                    : AppColors.textOnPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationPickerException implements Exception {
  final String message;

  const _LocationPickerException(this.message);
}
