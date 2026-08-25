import 'package:equatable/equatable.dart';
import 'sort_option.dart';

/// Filtros de búsqueda para mecánicos y talleres.
/// Los campos [radioKm], [specialtyIds] y [minRating] se envían
/// directamente como query params al backend.
class HomeFilters extends Equatable {
  final SortOption sortBy;
  final double minRating;

  /// Radio de búsqueda en km (5–50). Se envía al backend como [radiusKm].
  final double radioKm;

  /// IDs de especialidades seleccionadas para filtrar.
  final List<String> specialtyIds;

  /// Coordenadas opcionales para búsqueda cercana.
  final double? lat;
  final double? lon;

  const HomeFilters({
    this.sortBy = SortOption.rating,
    this.minRating = 0.0,
    this.radioKm = 20.0,
    this.specialtyIds = const [],
    this.lat,
    this.lon,
  });

  HomeFilters copyWith({
    SortOption? sortBy,
    double? minRating,
    double? radioKm,
    List<String>? specialtyIds,
    double? lat,
    double? lon,
    bool clearLocation = false,
  }) {
    return HomeFilters(
      sortBy: sortBy ?? this.sortBy,
      minRating: minRating ?? this.minRating,
      radioKm: radioKm ?? this.radioKm,
      specialtyIds: specialtyIds ?? this.specialtyIds,
      lat: clearLocation ? null : (lat ?? this.lat),
      lon: clearLocation ? null : (lon ?? this.lon),
    );
  }

  int get activeCount =>
      (sortBy != SortOption.rating ? 1 : 0) +
      (minRating != 0.0 ? 1 : 0) +
      (radioKm != 20.0 ? 1 : 0) +
      (specialtyIds.isNotEmpty ? 1 : 0);

  /// Convierte los filtros a query params para el backend.
  Map<String, dynamic> toQueryParams() {
    // El backend acepta: distancia | rating | rate
    String backendOrderBy;
    switch (sortBy) {
      case SortOption.cercania:
        backendOrderBy = 'distancia';
        break;
      case SortOption.rating:
      case SortOption.populares:
        backendOrderBy = 'rating';
        break;
    }

    return {
      'radiusKm': radioKm.toInt(),
      if (minRating > 0) 'minRating': minRating,
      if (specialtyIds.isNotEmpty) 'specialtyIds': specialtyIds,
      'orderBy': backendOrderBy,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lng': lon,
    };
  }

  @override
  List<Object?> get props =>
      [sortBy, minRating, radioKm, specialtyIds, lat, lon];
}
