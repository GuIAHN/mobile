import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/widgets/spare_part_wizard/request_location_picker_dialog.dart';
import '../../../home/presentation/widgets/spare_part_wizard/request_location_preview.dart';
import '../../../home/presentation/widgets/spare_part_wizard/request_location_selection.dart';

/// Selector de ubicación compartido por los registros de proveedores.
/// Usa la misma vista previa y el mismo mapa de la solicitud de repuestos.
class WorkshopLocationStep extends ConsumerStatefulWidget {
  final LatLng location;
  final ValueChanged<LatLng> onLocationChanged;
  final bool ubicacionConfirmada;
  final ValueChanged<bool> onUbicacionConfirmadaChanged;
  final String helperText;
  final bool autoLocate;

  const WorkshopLocationStep({
    super.key,
    required this.location,
    required this.onLocationChanged,
    required this.ubicacionConfirmada,
    required this.onUbicacionConfirmadaChanged,
    this.helperText =
        'Usa tu ubicación actual o mueve el mapa para ajustar el punto exacto.',
    this.autoLocate = true,
  });

  @override
  ConsumerState<WorkshopLocationStep> createState() =>
      _WorkshopLocationStepState();
}

class _WorkshopLocationStepState extends ConsumerState<WorkshopLocationStep> {
  RequestLocationSelection? _selection;
  bool _isLocating = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    if (widget.ubicacionConfirmada) {
      _selection = RequestLocationSelection(
        latitude: widget.location.latitude,
        longitude: widget.location.longitude,
        source: RequestLocationSource.profile,
      );
    } else if (widget.autoLocate) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _useCurrentLocation());
    }
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
        throw const _RegistrationLocationException(
          'Activa el servicio de ubicación o elige un punto en el mapa.',
        );
      }

      var permission = await service.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await service.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const _RegistrationLocationException(
          'No pudimos acceder al GPS. Puedes elegir un punto en el mapa.',
        );
      }

      final position = await service.getCurrentPosition();
      final label = await service.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (!mounted) return;
      _applySelection(
        RequestLocationSelection(
          latitude: position.latitude,
          longitude: position.longitude,
          label: label,
          source: RequestLocationSource.gps,
        ),
      );
    } on _RegistrationLocationException catch (error) {
      if (mounted) setState(() => _locationError = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationError =
              'No pudimos obtener tu ubicación. Intenta nuevamente o abre el mapa.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _applySelection(RequestLocationSelection selection) {
    setState(() {
      _selection = selection;
      _locationError = null;
    });
    widget.onLocationChanged(LatLng(selection.latitude, selection.longitude));
    widget.onUbicacionConfirmadaChanged(false);
  }

  Future<void> _openMap() async {
    final selection = await RequestLocationPickerDialog.show(
      context,
      initialCenter: _selection == null
          ? widget.location
          : LatLng(_selection!.latitude, _selection!.longitude),
      initialSelection: _selection,
    );
    if (!mounted || selection == null) return;
    _applySelection(selection);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'UBICACIÓN EN EL MAPA',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        if (_isLocating && _selection == null)
          const _LocatingState()
        else
          RequestLocationPreview(selection: _selection, onTap: _openMap),
        if (_locationError != null) ...[
          const SizedBox(height: 10),
          Semantics(
            liveRegion: true,
            child: Text(
              _locationError!,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.errorInk,
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('retry-registration-location'),
            onPressed: _isLocating ? null : _useCurrentLocation,
            icon: const Icon(Icons.my_location_rounded, size: 20),
            label: const Text('Usar mi ubicación actual'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        Text(
          widget.helperText,
          textAlign: TextAlign.center,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        AnimatedContainer(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: _selection == null
                ? const []
                : [
                    BoxShadow(
                      color: (widget.ubicacionConfirmada
                              ? AppColors.success
                              : AppColors.primary)
                          .withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: ElevatedButton(
            onPressed: _selection == null
                ? null
                : () => widget.onUbicacionConfirmadaChanged(
                      !widget.ubicacionConfirmada,
                    ),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.ubicacionConfirmada
                  ? AppColors.success
                  : AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.disabledBackground,
              disabledForegroundColor: AppColors.disabledText,
              elevation: 0,
              minimumSize: const Size.fromHeight(48),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  widget.ubicacionConfirmada
                      ? 'Ubicación Confirmada'
                      : 'Confirmar Ubicación',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Icon(Icons.check_circle, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LocatingState extends StatelessWidget {
  const _LocatingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('registration-location-loading'),
      constraints: const BoxConstraints(minHeight: 148),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 12),
            Text('Obteniendo tu ubicación actual…'),
          ],
        ),
      ),
    );
  }
}

class _RegistrationLocationException implements Exception {
  final String message;
  const _RegistrationLocationException(this.message);
}
