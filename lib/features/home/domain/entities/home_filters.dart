import 'package:equatable/equatable.dart';
import 'sort_option.dart';

/// Filtros de búsqueda para mecánicos y talleres.
/// Los campos [radioKm], [specialtyIds], [minRating] y [maxTarifa] se envían
/// directamente como query params al backend; [onlyOpen] es un filtro visual
/// local (el backend no lo soporta aún).
class HomeFilters extends Equatable {
  final SortOption sortBy;
  final double minRating;
  final bool onlyOpen;

  /// Radio de búsqueda en km (5–50). Se envía al backend como [radiusKm].
  final double radioKm;

  /// IDs de especialidades seleccionadas para filtrar.
  final List<String> specialtyIds;

  /// Tarifa máxima por hora (solo mecánicos). null = sin límite.
  final double? maxTarifa;

  /// Coordenadas opcionales para búsqueda cercana.
  final double? lat;
  final double? lon;

  const HomeFilters({
    this.sortBy = SortOption.cercania,
    this.minRating = 0.0,
    this.onlyOpen = false,
    this.radioKm = 20.0,
    this.specialtyIds = const [],
    this.maxTarifa,
    this.lat,
    this.lon,
  });

  HomeFilters copyWith({
    SortOption? sortBy,
    double? minRating,
    bool? onlyOpen,
    double? radioKm,
    List<String>? specialtyIds,
    double? maxTarifa,
    double? lat,
    double? lon,
    bool clearLocation = false,
    bool clearMaxTarifa = false,
  }) {
    return HomeFilters(
      sortBy: sortBy ?? this.sortBy,
      minRating: minRating ?? this.minRating,
      onlyOpen: onlyOpen ?? this.onlyOpen,
      radioKm: radioKm ?? this.radioKm,
      specialtyIds: specialtyIds ?? this.specialtyIds,
      maxTarifa: clearMaxTarifa ? null : (maxTarifa ?? this.maxTarifa),
      lat: clearLocation ? null : (lat ?? this.lat),
      lon: clearLocation ? null : (lon ?? this.lon),
    );
  }

  bool get isDefault =>
      sortBy == SortOption.cercania &&
      minRating == 0.0 &&
      !onlyOpen &&
      radioKm == 20.0 &&
      specialtyIds.isEmpty &&
      maxTarifa == null &&
      lat == null &&
      lon == null;

  int get activeCount =>
      (sortBy != SortOption.cercania ? 1 : 0) +
      (minRating != 0.0 ? 1 : 0) +
      (radioKm != 20.0 ? 1 : 0) +
      (specialtyIds.isNotEmpty ? 1 : 0) +
      (maxTarifa != null ? 1 : 0) +
      (onlyOpen ? 1 : 0);

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
      if (maxTarifa != null) 'maxTarifa': maxTarifa,
      if (specialtyIds.isNotEmpty) 'specialtyIds': specialtyIds,
      'orderBy': backendOrderBy,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lng': lon,
    };
  }

  @override
  List<Object?> get props =>
      [sortBy, minRating, onlyOpen, radioKm, specialtyIds, maxTarifa, lat, lon];
}
