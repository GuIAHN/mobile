import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/home_filters.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/sort_option.dart';

void main() {
  test('toQueryParams uses the backend Home filters contract', () {
    const filters = HomeFilters(
      radioKm: 35,
      minRating: 4.5,
      specialtyIds: ['brakes', 'diagnostics'],
      sortBy: SortOption.cercania,
      lat: 10.4806,
      lon: -66.9036,
    );

    expect(filters.toQueryParams(), {
      'radiusKm': 35,
      'minRating': 4.5,
      'specialtyIds': ['brakes', 'diagnostics'],
      'orderBy': 'distancia',
      'lat': 10.4806,
      'lng': -66.9036,
    });
  });
}
