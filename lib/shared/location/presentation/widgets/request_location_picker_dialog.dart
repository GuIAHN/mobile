import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google;
import 'package:latlong2/latlong.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/place_search_result.dart';
import '../../domain/entities/request_location_selection.dart';
import '../../../widgets/guia_google_map.dart';
import '../providers/places_providers.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  google.GoogleMapController? _mapController;
  RequestLocationSelection? _draft;
  LatLng? _cameraTarget;
  LatLng? _programmaticTarget;
  Timer? _reverseGeocodeDebounce;
  Timer? _mapReadinessTimer;
  bool _isLocating = false;
  bool _isMapMoving = false;
  bool _cameraMovementStarted = false;
  bool _isResolvingAddress = false;
  bool _isSearching = false;
  bool _isMapReady = false;
  bool _mapError = false;
  String? _locationError;
  String? _searchError;
  List<PlaceSearchResult>? _searchResults;
  List<String> _attributions = const [];
  int _selectionRevision = 0;
  int _searchRevision = 0;
  int _mapRevision = 0;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialSelection;
    _cameraTarget = _draft == null
        ? widget.initialCenter
        : LatLng(_draft!.latitude, _draft!.longitude);
    _isMapReady = widget.mapBuilder != null;
    if (widget.mapBuilder == null) _startMapReadinessTimer();
  }

  @override
  void dispose() {
    _reverseGeocodeDebounce?.cancel();
    _mapReadinessTimer?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _startMapReadinessTimer() {
    _mapReadinessTimer?.cancel();
    _mapReadinessTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && !_isMapReady) _handleMapError();
    });
  }

  void _handleMapCreated(google.GoogleMapController controller) {
    _mapController?.dispose();
    _mapController = controller;
    _mapReadinessTimer?.cancel();
    if (mounted) {
      setState(() {
        _isMapReady = true;
        _mapError = false;
      });
    }
  }

  void _handleMapError() {
    if (!mounted || _mapError) return;
    setState(() => _mapError = true);
  }

  void _retryMap() {
    _mapController?.dispose();
    _mapController = null;
    setState(() {
      _mapError = false;
      _isMapReady = widget.mapBuilder != null;
      _mapRevision++;
    });
    if (widget.mapBuilder == null) _startMapReadinessTimer();
  }

  Future<void> _selectPoint(
    LatLng point,
    RequestLocationSource source,
  ) async {
    final revision = ++_selectionRevision;
    setState(() {
      _draft = RequestLocationSelection(
        latitude: point.latitude,
        longitude: point.longitude,
        source: source,
      );
      _locationError = null;
      _isResolvingAddress = true;
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
      _isResolvingAddress = false;
      _draft = RequestLocationSelection(
        latitude: point.latitude,
        longitude: point.longitude,
        label: label,
        source: source,
      );
    });
  }

  void _onCameraMoveStarted() {
    _cameraMovementStarted = true;
    if (!_isMapMoving) setState(() => _isMapMoving = true);
  }

  void _onCameraMove(LatLng position) {
    _cameraTarget = position;
  }

  void _onCameraIdle() {
    // Google Maps can emit an idle callback after its initial render. That is
    // not a user selection and must not overwrite a saved/profile location.
    if (!_cameraMovementStarted) return;
    _cameraMovementStarted = false;
    final point = _cameraTarget ?? widget.initialCenter;
    final target = _programmaticTarget;
    if (target != null && _isSamePoint(target, point)) {
      _programmaticTarget = null;
      if (_isMapMoving) setState(() => _isMapMoving = false);
      return;
    }

    _reverseGeocodeDebounce?.cancel();
    setState(() {
      _isMapMoving = false;
      _isResolvingAddress = true;
      _locationError = null;
      _draft = RequestLocationSelection(
        latitude: point.latitude,
        longitude: point.longitude,
        source: RequestLocationSource.mapTap,
      );
    });
    _reverseGeocodeDebounce = Timer(
      const Duration(milliseconds: 450),
      () => _selectPoint(point, RequestLocationSource.mapTap),
    );
  }

  bool _isSamePoint(LatLng a, LatLng b) =>
      (a.latitude - b.latitude).abs() < 0.000001 &&
      (a.longitude - b.longitude).abs() < 0.000001;

  Future<void> _moveMap(LatLng point, {double zoom = 16}) async {
    _cameraTarget = point;
    _programmaticTarget = point;
    await _mapController?.animateCamera(
      google.CameraUpdate.newCameraPosition(
        google.CameraPosition(
          target: google.LatLng(point.latitude, point.longitude),
          zoom: zoom,
        ),
      ),
    );
  }

  Future<void> _handleMapTap(LatLng point) async {
    _reverseGeocodeDebounce?.cancel();
    if (widget.mapBuilder == null) await _moveMap(point);
    await _selectPoint(point, RequestLocationSource.mapTap);
  }

  Future<void> _useCurrentLocation() async {
    if (_isLocating) return;
    _reverseGeocodeDebounce?.cancel();
    _selectionRevision++;
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
      if (widget.mapBuilder == null) await _moveMap(point);
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

  Future<void> _searchPlaces() async {
    final query = _searchController.text.trim();
    if (query.length < 3) {
      setState(() {
        _searchError = 'Escribe al menos 3 caracteres.';
        _searchResults = null;
      });
      return;
    }

    final revision = ++_searchRevision;
    setState(() {
      _isSearching = true;
      _searchError = null;
      _searchResults = null;
      _attributions = const [];
    });

    try {
      final outcome = await ref.read(searchPlacesUseCaseProvider)(query);
      if (!mounted || revision != _searchRevision) return;
      final response = outcome.fold(
        (failure) => throw failure,
        (value) => value,
      );
      setState(() {
        _isSearching = false;
        _searchResults = response.results;
        _attributions = response.attributions;
      });
    } catch (error) {
      if (!mounted || revision != _searchRevision) return;
      setState(() {
        _isSearching = false;
        _searchError = error is Failure
            ? error.message
            : 'No pudimos buscar ubicaciones. Intenta nuevamente.';
        _searchResults = null;
      });
    }
  }

  Future<void> _selectSearchResult(PlaceSearchResult result) async {
    _searchRevision++;
    _selectionRevision++;
    _reverseGeocodeDebounce?.cancel();
    final point = LatLng(result.latitude, result.longitude);
    setState(() {
      _draft = RequestLocationSelection(
        latitude: result.latitude,
        longitude: result.longitude,
        label: result.formattedAddress,
        source: RequestLocationSource.search,
      );
      _isResolvingAddress = false;
      _isMapMoving = false;
      _locationError = null;
      _searchResults = null;
      _searchError = null;
    });
    _searchFocus.unfocus();
    if (widget.mapBuilder == null) await _moveMap(point);
  }

  Widget _buildMap(BuildContext context) {
    final customBuilder = widget.mapBuilder;
    if (customBuilder != null) {
      return customBuilder(
        context,
        _draft,
        _handleMapTap,
        _handleMapError,
      );
    }

    final center = _cameraTarget ?? widget.initialCenter;
    return GuiaGoogleMap(
      key: ValueKey('request-location-google-map-$_mapRevision'),
      initialCenter: center,
      initialZoom: _draft == null ? 12 : 15,
      onMapCreated: _handleMapCreated,
      onCameraMoveStarted: _onCameraMoveStarted,
      onCameraMove: _onCameraMove,
      onCameraIdle: _onCameraIdle,
      onTap: _handleMapTap,
      padding: const EdgeInsets.only(bottom: 190),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selection = _draft;
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final resultsHeight =
                  math.min(320.0, constraints.maxHeight * .38);
              return Stack(
                children: [
                  Positioned.fill(child: _buildMap(context)),
                  if (widget.mapBuilder == null && !_mapError && !_isMapReady)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: AppColors.grey100,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  if (widget.mapBuilder == null && !_mapError)
                    Center(
                      child: Transform.translate(
                        offset: const Offset(0, -24),
                        child: AnimatedSlide(
                          offset: _isMapMoving
                              ? const Offset(0, -0.12)
                              : Offset.zero,
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 140),
                          curve: Curves.easeOut,
                          child: const _CenterLocationPin(),
                        ),
                      ),
                    ),
                  if (_mapError) _buildMapError(),
                  _buildTopBar(),
                  _buildSearchBox(),
                  if (_isSearching ||
                      _searchError != null ||
                      _searchResults != null)
                    Positioned(
                      top: 144,
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: resultsHeight),
                        child: _buildSearchResults(),
                      ),
                    ),
                  Positioned(
                    right: AppSpacing.lg,
                    bottom: 190,
                    child: _buildCurrentLocationButton(),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildSelectionSheet(selection),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
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
                  icon: const Icon(AppIcons.close),
                ),
              ),
              Expanded(
                child: Text(
                  'Elegir ubicación',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Positioned(
      top: 80,
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      child: Material(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: TextField(
          key: const Key('request-location-search'),
          controller: _searchController,
          focusNode: _searchFocus,
          textInputAction: TextInputAction.search,
          autocorrect: false,
          onSubmitted: (_) => _searchPlaces(),
          onChanged: (_) {
            if (_searchError != null || _searchResults != null) {
              setState(() {
                _searchError = null;
                _searchResults = null;
              });
            }
          },
          style: AppTypography.body,
          decoration: InputDecoration(
            hintText: 'Buscar dirección o lugar',
            hintStyle: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
            prefixIcon: const Icon(AppIcons.search),
            suffixIcon: Semantics(
              button: true,
              enabled: !_isSearching,
              label: 'Buscar ubicación',
              excludeSemantics: true,
              child: TextButton(
                key: const Key('submit-request-location-search'),
                onPressed: _isSearching ? null : _searchPlaces,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  disabledForegroundColor: AppColors.textDisabled,
                  minimumSize: const Size(64, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: AppTypography.label,
                ),
                child: const Text('Buscar'),
              ),
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Material(
      color: AppColors.surface,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        liveRegion: true,
        child: _isSearching
            ? const SizedBox(
                height: 88,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            : _searchError != null
                ? _SearchMessage(
                    icon: AppIcons.connectivityError,
                    message: _searchError!,
                    actionLabel: 'Reintentar',
                    onAction: _searchPlaces,
                  )
                : _searchResults!.isEmpty
                    ? const _SearchMessage(
                        icon: AppIcons.searchEmpty,
                        message:
                            'No encontramos resultados. Prueba otra búsqueda.',
                      )
                    : ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        children: [
                          for (final result in _searchResults!)
                            ListTile(
                              minVerticalPadding: 10,
                              leading: const Icon(
                                AppIcons.location,
                                color: AppColors.primary,
                              ),
                              title: Text(
                                result.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    AppTypography.title.copyWith(fontSize: 14),
                              ),
                              subtitle: Text(
                                result.formattedAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySm,
                              ),
                              onTap: () => _selectSearchResult(result),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                            child: Text(
                              _attributionText,
                              style: AppTypography.meta.copyWith(
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }

  String get _attributionText {
    final thirdParty = _attributions
        .map((value) => value.replaceAll(RegExp(r'<[^>]*>'), '').trim())
        .where((value) => value.isNotEmpty)
        .join(' · ');
    return thirdParty.isEmpty ? 'Google Maps' : 'Google Maps · $thirdParty';
  }

  Widget _buildMapError() {
    return Positioned(
      top: 148,
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      child: Semantics(
        container: true,
        liveRegion: true,
        label: 'No pudimos cargar el mapa. Reintentar carga del mapa.',
        excludeSemantics: true,
        child: Material(
          color: AppColors.surface,
          elevation: 2,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 4),
            child: Row(
              children: [
                const Icon(AppIcons.map, color: AppColors.errorInk),
                const SizedBox(width: 8),
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
    );
  }

  Widget _buildCurrentLocationButton() {
    return Semantics(
      button: true,
      label: 'Usar mi ubicación actual',
      excludeSemantics: true,
      child: SizedBox(
        width: 48,
        height: 48,
        child: FloatingActionButton(
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
    );
  }

  Widget _buildSelectionSheet(RequestLocationSelection? selection) {
    return Container(
      constraints: const BoxConstraints(minHeight: 172),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('UBICACIÓN SELECCIONADA', style: AppTypography.overline),
            const SizedBox(height: 8),
            Text(
              _isMapMoving
                  ? 'Suelta el mapa para elegir este punto.'
                  : _isResolvingAddress
                      ? 'Buscando dirección…'
                      : selection?.displayLabel ??
                          'Busca una dirección o mueve el mapa.',
              style: AppTypography.body.copyWith(
                color: selection == null
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
            if (selection != null && !_isMapMoving && !_isResolvingAddress) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    AppIcons.location,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child:
                        Text(selection.sourceLabel, style: AppTypography.meta),
                  ),
                ],
              ),
            ],
            if (_locationError != null) ...[
              const SizedBox(height: 8),
              Text(
                _locationError!,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.errorInk,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeightLg,
              child: ElevatedButton(
                key: const Key('confirm-request-location'),
                onPressed:
                    selection == null || _isMapMoving || _isResolvingAddress
                        ? null
                        : () => Navigator.pop(context, selection),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  disabledBackgroundColor: AppColors.disabledBackground,
                  disabledForegroundColor: AppColors.disabledText,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
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
    );
  }
}

class _SearchMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SearchMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: AppTypography.bodySm)),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class _CenterLocationPin extends StatelessWidget {
  const _CenterLocationPin();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ubicación seleccionada en el centro del mapa',
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(AppIcons.location, color: Colors.white, size: 30),
      ),
    );
  }
}

class _LocationPickerException implements Exception {
  final String message;
  const _LocationPickerException(this.message);
}
