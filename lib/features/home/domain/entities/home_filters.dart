import 'package:equatable/equatable.dart';
import 'sort_option.dart';

class HomeFilters extends Equatable {
  final SortOption sortBy;
  final double maxDistance;
  final double minRating;
  final bool onlyOpen;

  const HomeFilters({
    this.sortBy = SortOption.cercania,
    this.maxDistance = 5.0,
    this.minRating = 0.0,
    this.onlyOpen = false,
  });

  HomeFilters copyWith({
    SortOption? sortBy,
    double? maxDistance,
    double? minRating,
    bool? onlyOpen,
  }) {
    return HomeFilters(
      sortBy: sortBy ?? this.sortBy,
      maxDistance: maxDistance ?? this.maxDistance,
      minRating: minRating ?? this.minRating,
      onlyOpen: onlyOpen ?? this.onlyOpen,
    );
  }

  bool get isDefault =>
      sortBy == SortOption.cercania &&
      maxDistance == 5.0 &&
      minRating == 0.0 &&
      !onlyOpen;

  int get activeCount =>
      (sortBy != SortOption.cercania ? 1 : 0) +
      (maxDistance != 5.0 ? 1 : 0) +
      (minRating != 0.0 ? 1 : 0) +
      (onlyOpen ? 1 : 0);

  @override
  List<Object?> get props => [sortBy, maxDistance, minRating, onlyOpen];
}
