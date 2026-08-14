enum RequestLocationSource { gps, profile, mapTap }

class RequestLocationSelection {
  final double latitude;
  final double longitude;
  final String? label;
  final RequestLocationSource source;

  const RequestLocationSelection({
    required this.latitude,
    required this.longitude,
    required this.source,
    this.label,
  });

  String get displayLabel =>
      label ??
      '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';

  String get sourceLabel => switch (source) {
        RequestLocationSource.gps => 'Ubicación GPS',
        RequestLocationSource.profile => 'Última ubicación guardada',
        RequestLocationSource.mapTap => 'Punto elegido en el mapa',
      };
}
