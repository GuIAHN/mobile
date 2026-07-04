import 'package:equatable/equatable.dart';
import 'sort_option.dart';

/// Filtros de búsqueda para mecánicos y talleres.
/// Los campos [radioKm] y [specialtyIds] se envían directamente como query
/// params al backend; los demás también son enviados al backend excepto
/// [onlyOpen], que es un filtro visual local (el backend no lo soporta aún).
class HomeFilters extends Equatable {
  final SortOption sortBy;
  final double minRating;
  final bool onlyOpen;

  /// Radio de búsqueda en km (5–50). Se envía al backend como [radioKm].
  final double radioKm;

  /// IDs de especialidades seleccionadas para filtrar.
  final List<String> specialtyIds;

  /// Coordenadas opcionales para búsqueda cercana.
  final double? lat;
  final double? lon;

  const HomeFilters({
    this.sortBy = SortOption.cercania,
    this.minRating = 0.0,
    this.onlyOpen = false,
    this.radioKm = 15.0,
    this.specialtyIds = const [],
    this.lat,
    this.lon,
  });

  HomeFilters copyWith({
    SortOption? sortBy,
    double? minRating,
    bool? onlyOpen,
    double? radioKm,
    List<String>? specialtyIds,
    double? lat,
    double? lon,
    bool clearLocation = false,
  }) {
    return HomeFilters(
      sortBy: sortBy ?? this.sortBy,
      minRating: minRating ?? this.minRating,
      onlyOpen: onlyOpen ?? this.onlyOpen,
      radioKm: radioKm ?? this.radioKm,
      specialtyIds: specialtyIds ?? this.specialtyIds,
      lat: clearLocation ? null : (lat ?? this.lat),
      lon: clearLocation ? null : (lon ?? this.lon),
    );
  }

  bool get isDefault =>
      sortBy == SortOption.cercania &&
      minRating == 0.0 &&
      !onlyOpen &&
      radioKm == 15.0 &&
      specialtyIds.isEmpty &&
      lat == null &&
      lon == null;

  int get activeCount =>
      (sortBy != SortOption.cercania ? 1 : 0) +
      (minRating != 0.0 ? 1 : 0) +
      (radioKm != 15.0 ? 1 : 0) +
      (specialtyIds.isNotEmpty ? 1 : 0) +
      (onlyOpen ? 1 : 0);

  /// Convierte los filtros a query params para el backend.
  Map<String, dynamic> toQueryParams() {
    return {
      'radioKm': radioKm.toInt(),
      if (minRating > 0) 'minRating': minRating,
      if (specialtyIds.isNotEmpty) 'specialtyIds': specialtyIds,
      'orderBy': sortBy == SortOption.rating ? 'rating' : 'distancia',
      if (lat != null) 'lat': lat,
      if (lon != null) 'lng': lon,
    };
  }

  @override
  List<Object?> get props =>
      [sortBy, minRating, onlyOpen, radioKm, specialtyIds, lat, lon];
}
