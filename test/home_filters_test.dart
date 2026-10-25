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
  test(
      'all offered sort, radius and rating options serialize to supported values',
      () {
    for (final sort in SortOption.values) {
      for (final radius in [5.0, 10.0, 20.0, 30.0, 50.0]) {
        for (final rating in [0.0, 3.0, 4.0, 4.5]) {
          final filters =
              HomeFilters(sortBy: sort, radioKm: radius, minRating: rating);
          final params = filters.toQueryParams();
          expect(params['radiusKm'], radius.toInt());
          expect(params['minRating'], rating == 0 ? null : rating);
          expect(params['orderBy'],
              sort == SortOption.cercania ? 'distancia' : 'rating');
          expect(params.containsKey('specialtyIds'), isFalse);
        }
      }
    }
  });
}
