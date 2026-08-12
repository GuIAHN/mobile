import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/service_type.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/home_item.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/providers/home_providers.dart';

HomeItem provider({
  required String id,
  required String name,
  required double rating,
  required int reviews,
  required double distanceKm,
}) {
  return HomeItem(
    id: id,
    name: name,
    detail: 'Automotive service',
    rating: rating,
    reviews: reviews,
    distanceKm: distanceKm,
    isOpen: true,
    iconName: 'warehouse_outlined',
    type: ServiceType.workshops,
  );
}

ProviderContainer containerWith(List<HomeItem> items) {
  return ProviderContainer(
    overrides: [
      homeItemsProvider.overrideWith((ref, type) async => items),
    ],
  );
}

Future<List<HomeItem>> readTopProviders(ProviderContainer container) async {
  await container.read(homeItemsProvider(ServiceType.workshops).future);
  return container
      .read(topProvidersProvider(ServiceType.workshops))
      .requireValue;
}

void main() {
  test('ranks a higher rating ahead of more reviews and a shorter distance',
      () async {
    final container = containerWith([
      provider(
        id: 'well-reviewed-nearby',
        name: 'Well Reviewed Nearby',
        rating: 4.8,
        reviews: 800,
        distanceKm: 0.2,
      ),
      provider(
        id: 'highest-rating',
        name: 'Highest Rating',
        rating: 4.9,
        reviews: 1,
        distanceKm: 10,
      ),
    ]);
    addTearDown(container.dispose);

    final result = await readTopProviders(container);

    expect(result.map((item) => item.id),
        ['highest-rating', 'well-reviewed-nearby']);
  });

  test('ranks more reviews ahead when ratings are equal', () async {
    final container = containerWith([
      provider(
        id: 'nearby-fewer-reviews',
        name: 'Nearby Fewer Reviews',
        rating: 4.8,
        reviews: 10,
        distanceKm: 0.2,
      ),
      provider(
        id: 'farther-more-reviews',
        name: 'Farther More Reviews',
        rating: 4.8,
        reviews: 40,
        distanceKm: 8,
      ),
    ]);
    addTearDown(container.dispose);

    final result = await readTopProviders(container);

    expect(result.map((item) => item.id),
        ['farther-more-reviews', 'nearby-fewer-reviews']);
  });

  test('ranks a shorter distance ahead when ratings and reviews are equal',
      () async {
    final container = containerWith([
      provider(
        id: 'farther',
        name: 'Farther Workshop',
        rating: 4.8,
        reviews: 40,
        distanceKm: 5,
      ),
      provider(
        id: 'nearer',
        name: 'Nearer Workshop',
        rating: 4.8,
        reviews: 40,
        distanceKm: 1,
      ),
    ]);
    addTearDown(container.dispose);

    final result = await readTopProviders(container);

    expect(result.map((item) => item.id), ['nearer', 'farther']);
  });

  test('returns only the three highest-ranked providers', () async {
    final container = containerWith([
      provider(
          id: 'fourth', name: 'Fourth', rating: 4.5, reviews: 5, distanceKm: 1),
      provider(
          id: 'second', name: 'Second', rating: 4.8, reviews: 5, distanceKm: 1),
      provider(
          id: 'fifth', name: 'Fifth', rating: 4.4, reviews: 5, distanceKm: 1),
      provider(
          id: 'first', name: 'First', rating: 4.9, reviews: 5, distanceKm: 1),
      provider(
          id: 'third', name: 'Third', rating: 4.7, reviews: 5, distanceKm: 1),
    ]);
    addTearDown(container.dispose);

    final result = await readTopProviders(container);

    expect(result.map((item) => item.id), ['first', 'second', 'third']);
  });

  test('does not mutate the home items list while ranking', () async {
    final input = [
      provider(
          id: 'second', name: 'Second', rating: 4.8, reviews: 5, distanceKm: 1),
      provider(
          id: 'first', name: 'First', rating: 4.9, reviews: 5, distanceKm: 1),
    ];
    final container = containerWith(input);
    addTearDown(container.dispose);

    await readTopProviders(container);

    expect(input.map((item) => item.id), ['second', 'first']);
  });
}
