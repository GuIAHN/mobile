import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/service_type.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/user_role.dart';
import 'package:guiautomotriz_mobile/core/error/failures.dart';
import 'package:guiautomotriz_mobile/core/providers/current_user_provider.dart';
import 'package:guiautomotriz_mobile/core/services/location_service.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/home_filters.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/home_item.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/promo.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/provider_detail.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/top_providers_result.dart';
import 'package:guiautomotriz_mobile/features/home/domain/repositories/home_repository.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/providers/home_providers.dart';

class _FakeHomeRepository implements HomeRepository {
  _FakeHomeRepository(this.result);

  final TopProvidersResult result;
  int calls = 0;
  double? receivedLat;
  double? receivedLng;
  HomeFilters? receivedFilters;

  @override
  Future<Either<Failure, TopProvidersResult>> getTopProviders({
    double? lat,
    double? lng,
  }) async {
    calls++;
    receivedLat = lat;
    receivedLng = lng;
    return Right(result);
  }

  @override
  Future<Either<Failure, List<HomeItem>>> getHomeItems(ServiceType type) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<Promo>>> getPromos(ServiceType type) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, ProviderDetail>> getProviderDetail({
    required String id,
    required ServiceType type,
  }) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<HomeItem>>> searchProviders({
    required ServiceType type,
    required HomeFilters filters,
    int page = 1,
  }) async {
    receivedFilters = filters;
    return const Right([]);
  }
}

class _FixedLocationNotifier extends UserLocationNotifier {
  _FixedLocationNotifier(Position position) : super(LocationService()) {
    state = AsyncValue.data(position);
  }
}

HomeItem provider(String id, ServiceType type) => HomeItem(
      id: id,
      name: id,
      detail: 'Servicio automotriz',
      rating: 4.8,
      reviews: 20,
      distanceKm: null,
      isOpen: null,
      iconName: type == ServiceType.workshops
          ? 'warehouse_outlined'
          : 'build_outlined',
      type: type,
    );

TopProvidersResult groupedResult() => TopProvidersResult(
      workshops: [
        provider('backend-first', ServiceType.workshops),
        provider('backend-second', ServiceType.workshops),
        provider('backend-third', ServiceType.workshops),
        provider('backend-fourth', ServiceType.workshops),
      ],
      mechanics: [provider('mechanic-first', ServiceType.mechanic)],
    );

Future<void> loadBothGroups(ProviderContainer container) async {
  final workshops = container.listen(
    topProvidersProvider(ServiceType.workshops),
    (_, __) {},
    fireImmediately: true,
  );
  final mechanics = container.listen(
    topProvidersProvider(ServiceType.mechanic),
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(workshops.close);
  addTearDown(mechanics.close);
  await container.read(homeTopProvidersProvider.future);
}

void main() {
  test('both sections share one fetch and preserve the backend collections',
      () async {
    final repository = _FakeHomeRepository(groupedResult());
    final container = ProviderContainer(
      overrides: [
        homeRepositoryProvider.overrideWithValue(repository),
        currentRoleProvider.overrideWithValue(UserRole.consumer),
      ],
    );
    addTearDown(container.dispose);

    await loadBothGroups(container);

    final workshops = container
        .read(topProvidersProvider(ServiceType.workshops))
        .requireValue;
    final mechanics =
        container.read(topProvidersProvider(ServiceType.mechanic)).requireValue;
    expect(repository.calls, 1);
    expect(
      workshops.map((item) => item.id),
      ['backend-first', 'backend-second', 'backend-third', 'backend-fourth'],
    );
    expect(mechanics.single.id, 'mechanic-first');
  });

  test('keeps the grouped Home response warm between tab visits', () async {
    final repository = _FakeHomeRepository(groupedResult());
    final container = ProviderContainer(
      overrides: [
        homeRepositoryProvider.overrideWithValue(repository),
        currentRoleProvider.overrideWithValue(UserRole.consumer),
      ],
    );
    addTearDown(container.dispose);

    final firstVisit = container.listen(
      topProvidersProvider(ServiceType.workshops),
      (_, __) {},
      fireImmediately: true,
    );
    await container.read(homeTopProvidersProvider.future);
    firstVisit.close();
    await Future<void>.delayed(Duration.zero);

    final secondVisit = container.listen(
      topProvidersProvider(ServiceType.workshops),
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(secondVisit.close);
    await container.read(homeTopProvidersProvider.future);

    expect(repository.calls, 1);
  });

  test('active location is sent once to the grouped fetch', () async {
    final repository = _FakeHomeRepository(groupedResult());
    final position = Position(
      longitude: -66.9036,
      latitude: 10.4806,
      timestamp: DateTime(2026),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
    final container = ProviderContainer(
      overrides: [
        homeRepositoryProvider.overrideWithValue(repository),
        currentRoleProvider.overrideWithValue(UserRole.mechanic),
        isLocationSharedProvider.overrideWith((ref) => true),
        userLocationProvider.overrideWith(
          (ref) => _FixedLocationNotifier(position),
        ),
      ],
    );
    addTearDown(container.dispose);

    await loadBothGroups(container);

    expect(repository.calls, 1);
    expect(repository.receivedLat, 10.4806);
    expect(repository.receivedLng, -66.9036);
  });

  test('store and workshop top providers use only the saved profile location',
      () async {
    for (final role in [UserRole.store, UserRole.workshop]) {
      final repository = _FakeHomeRepository(groupedResult());
      final position = Position(
        longitude: -66.9036,
        latitude: 10.4806,
        timestamp: DateTime(2026),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      final container = ProviderContainer(
        overrides: [
          homeRepositoryProvider.overrideWithValue(repository),
          currentRoleProvider.overrideWithValue(role),
          isLocationSharedProvider.overrideWith((ref) => true),
          userLocationProvider.overrideWith(
            (ref) => _FixedLocationNotifier(position),
          ),
        ],
      );
      addTearDown(container.dispose);

      await loadBothGroups(container);

      expect(repository.receivedLat, isNull, reason: role.name);
      expect(repository.receivedLng, isNull, reason: role.name);
    }
  });

  test('store and workshop list searches ignore temporary coordinates',
      () async {
    for (final role in [UserRole.store, UserRole.workshop]) {
      final repository = _FakeHomeRepository(groupedResult());
      final position = Position(
        longitude: -66.9036,
        latitude: 10.4806,
        timestamp: DateTime(2026),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      final container = ProviderContainer(
        overrides: [
          homeRepositoryProvider.overrideWithValue(repository),
          currentRoleProvider.overrideWithValue(role),
          homeFiltersProvider.overrideWith(
            (ref) => const HomeFilters(lat: 9.5, lon: -66.8),
          ),
          isLocationSharedProvider.overrideWith((ref) => true),
          userLocationProvider.overrideWith(
            (ref) => _FixedLocationNotifier(position),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(homeItemsProvider(ServiceType.mechanic).future);

      expect(repository.receivedFilters?.lat, isNull, reason: role.name);
      expect(repository.receivedFilters?.lon, isNull, reason: role.name);
    }
  });

  test('inactive location omits coordinates from the grouped fetch', () async {
    final repository = _FakeHomeRepository(groupedResult());
    final container = ProviderContainer(
      overrides: [
        homeRepositoryProvider.overrideWithValue(repository),
        currentRoleProvider.overrideWithValue(UserRole.consumer),
      ],
    );
    addTearDown(container.dispose);

    await loadBothGroups(container);

    expect(repository.calls, 1);
    expect(repository.receivedLat, isNull);
    expect(repository.receivedLng, isNull);
  });
}
