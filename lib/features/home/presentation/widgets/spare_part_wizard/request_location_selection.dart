enum RequestLocationSource { gps, mapTap }

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
}
