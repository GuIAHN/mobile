import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/guia_map.dart';

class WorkshopLocationStep extends StatefulWidget {
  final LatLng location;
  final ValueChanged<LatLng> onLocationChanged;
  final bool ubicacionConfirmada;
  final ValueChanged<bool> onUbicacionConfirmadaChanged;
  final String searchHint;
  final String helperText;

  const WorkshopLocationStep({
    super.key,
    required this.location,
    required this.onLocationChanged,
    required this.ubicacionConfirmada,
    required this.onUbicacionConfirmadaChanged,
    this.searchHint = 'Buscar dirección del taller...',
    this.helperText =
        'Toca el mapa para ajustar la ubicación exacta del taller',
  });

  @override
  State<WorkshopLocationStep> createState() => _WorkshopLocationStepState();
}

class _WorkshopLocationStepState extends State<WorkshopLocationStep> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String? _searchError;
  int _mapRevision = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchAddress() async {
    if (_isSearching) return;

    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _searchError = 'Escribe una dirección para buscarla.');
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      final results = await Geocoding().locationFromAddress(query);
      if (!mounted) return;
      if (results.isEmpty) {
        setState(() {
          _searchError =
              'No encontramos esa dirección. Intenta con más detalles.';
        });
        return;
      }

      final result = results.first;
      widget.onLocationChanged(LatLng(result.latitude, result.longitude));
      widget.onUbicacionConfirmadaChanged(false);
      setState(() => _mapRevision++);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchError =
            'No pudimos buscar la dirección. Revisa tu conexión e intenta de nuevo.';
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectLocation(LatLng point) {
    widget.onLocationChanged(point);
    widget.onUbicacionConfirmadaChanged(false);
    if (_searchError != null) setState(() => _searchError = null);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'DIRECCIÓN',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          enabled: !_isSearching,
          textInputAction: TextInputAction.search,
          autofillHints: const [AutofillHints.fullStreetAddress],
          onSubmitted: (_) => _searchAddress(),
          style: GoogleFonts.hankenGrotesk(
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.searchHint,
            hintStyle: GoogleFonts.hankenGrotesk(
              fontSize: 15,
              color: AppColors.textDisabled,
            ),
            prefixIcon: const Icon(
              Icons.search,
              size: 20,
              color: AppColors.textSecondary,
            ),
            suffixIcon: _isSearching
                ? const Center(
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : IconButton(
                    tooltip: 'Buscar dirección',
                    onPressed: _searchAddress,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    color: AppColors.primary,
                  ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        if (_searchError != null) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              _searchError!,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.errorInk,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        GuiaMap(
          mapKey: ValueKey('registration-location-map-$_mapRevision'),
          point: widget.location,
          height: 300,
          borderRadius: 24,
          onTap: _selectLocation,
        ),
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
            boxShadow: [
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
            onPressed: () {
              widget.onUbicacionConfirmadaChanged(
                !widget.ubicacionConfirmada,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.ubicacionConfirmada
                  ? AppColors.success
                  : AppColors.primary,
              foregroundColor: Colors.white,
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
