import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/service_type.dart';
import 'package:guiautomotriz_mobile/features/home/data/datasources/home_remote_datasource.dart';
import 'package:guiautomotriz_mobile/features/home/data/datasources/search_remote_datasource.dart';
import 'package:guiautomotriz_mobile/features/home/data/repositories/home_repository_impl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/home_filters.dart';

class _MockSearchRemoteDatasource extends Mock
    implements SearchRemoteDatasource {}

class _MockHomeRemoteDatasource extends Mock implements HomeRemoteDatasource {}

void main() {
  for (final type in [ServiceType.workshops, ServiceType.mechanic]) {
    test('preserves pagination metadata for ${type.name}', () async {
      final source = _MockSearchRemoteDatasource();
      final home = _MockHomeRemoteDatasource();
      final response = {
        'data': [
          {'id': 'provider-21', 'nombre': 'Proveedor 21'}
        ],
        'total': 41,
        'page': 2,
        'pageSize': 20,
      };
      when(() => source.searchWorkshops(any()))
          .thenAnswer((_) async => response);
      when(() => source.searchMechanics(any()))
          .thenAnswer((_) async => response);
      final result = await HomeRepositoryImpl(source, home).searchProvidersPage(
        type: type,
        filters: const HomeFilters(),
        page: 2,
      );
      final page = result.getOrElse(() => throw StateError('unexpected error'));
      expect(page.items.single.id, 'provider-21');
      expect(page.total, 41);
      expect(page.page, 2);
      expect(page.hasMore, isTrue);
      final params = verify(() => type == ServiceType.workshops
          ? source.searchWorkshops(captureAny())
          : source.searchMechanics(captureAny())).captured.single as Map;
      expect(params['page'], 2);
      expect(params['pageSize'], 20);
    });
  }

  test('maps both grouped collections without changing backend order',
      () async {
    final searchDatasource = _MockSearchRemoteDatasource();
    final homeDatasource = _MockHomeRemoteDatasource();
    when(
      () => homeDatasource.getTopProviders(lat: 10.4, lng: -66.9),
    ).thenAnswer(
      (_) async => {
        'workshops': [
          {
            'id': 'workshop-2',
            'name': 'Segundo según backend',
            'rating': 4.7,
            'ratingCount': 20,
            'distanceKm': 2.0,
            'specialties': ['Frenos'],
          },
          {
            'id': 'workshop-1',
            'name': 'Primero por nombre, no por ranking',
            'rating': 4.9,
            'ratingCount': 30,
            'distanceKm': 1.0,
            'specialties': ['Motor'],
          },
        ],
        'mechanics': [
          {
            'id': 'mechanic-1',
            'name': 'Ana',
            'rating': 4.8,
            'ratingCount': 12,
            'distanceKm': null,
            'specialties': ['Inyección'],
          },
        ],
      },
    );
    final repository = HomeRepositoryImpl(searchDatasource, homeDatasource);

    final either = await repository.getTopProviders(lat: 10.4, lng: -66.9);
    final result = either.getOrElse(() => throw StateError('unexpected left'));

    expect(
        result.workshops.map((item) => item.id), ['workshop-2', 'workshop-1']);
    expect(result.workshops.every((item) => item.type == ServiceType.workshops),
        isTrue);
    expect(result.mechanics.single.id, 'mechanic-1');
    expect(result.mechanics.single.type, ServiceType.mechanic);
  });

  test('uses the stores endpoint when live stores are enabled', () async {
    final searchDatasource = _MockSearchRemoteDatasource();
    final homeDatasource = _MockHomeRemoteDatasource();
    when(() => searchDatasource.searchStores(any())).thenAnswer(
      (_) async => {
        'data': [
          {
            'id': 'store-1',
            'nombre': 'Repuestos Central',
            'descripcion': 'Caracas',
            'rating': 4.8,
            'ratingCount': 12,
            'hasDelivery': true,
            'especialidades': ['Motor'],
          },
        ],
      },
    );
    final repository = HomeRepositoryImpl(
      searchDatasource,
      homeDatasource,
      useLiveStores: true,
    );

    final either = await repository.getHomeItems(ServiceType.spareParts);
    final stores = either.getOrElse(() => throw StateError('unexpected left'));

    expect(stores.single.id, 'store-1');
    expect(stores.single.name, 'Repuestos Central');
    expect(stores.single.type, ServiceType.spareParts);
    verify(() => searchDatasource.searchStores(any())).called(1);
  });

  test('keeps local spare-parts data when live stores are disabled', () async {
    final searchDatasource = _MockSearchRemoteDatasource();
    final homeDatasource = _MockHomeRemoteDatasource();
    final repository = HomeRepositoryImpl(
      searchDatasource,
      homeDatasource,
      useLiveStores: false,
    );

    final either = await repository.getHomeItems(ServiceType.spareParts);
    final stores = either.getOrElse(() => throw StateError('unexpected left'));

    expect(stores, isNotEmpty);
    expect(stores.every((store) => store.id == null), isTrue);
    verifyNever(() => searchDatasource.searchStores(any()));
  });
}
