import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/service_type.dart';
import 'package:guiautomotriz_mobile/core/network/dio_client.dart';
import 'package:guiautomotriz_mobile/core/network/interceptors/response_unwrap_interceptor.dart';
import 'package:guiautomotriz_mobile/features/home/data/datasources/home_remote_datasource.dart';
import 'package:guiautomotriz_mobile/features/home/data/datasources/search_remote_datasource.dart';
import 'package:guiautomotriz_mobile/features/home/data/repositories/home_repository_impl.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/home_filters.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/sort_option.dart';

class _Adapter implements HttpClientAdapter {
  late RequestOptions request;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    request = options;
    return ResponseBody.fromString(
        jsonEncode({
          'data': {
            'data': [
              {
                'id': 'match',
                'nombre': 'Proveedor compatible',
                'rating': 4.8,
                'ratingCount': 37,
                'especialidades': ['Frenos']
              }
            ],
            'total': 41,
            'page': 2,
            'pageSize': 20,
          }
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  for (final type in [ServiceType.workshops, ServiceType.mechanic]) {
    for (final specialties in [
      <String>[],
      ['brakes'],
      ['brakes', 'engine']
    ]) {
      for (final sort in SortOption.values) {
        test(
            'transports ${specialties.length} specialties and ${sort.name} for ${type.name}',
            () async {
          final container = ProviderContainer();
          addTearDown(container.dispose);
          final client = container.read(dioClientProvider);
          client.dio.interceptors
            ..clear()
            ..add(ResponseUnwrapInterceptor());
          final adapter = _Adapter();
          client.dio.httpClientAdapter = adapter;
          addTearDown(() => client.dio.close());
          final repository = HomeRepositoryImpl(
              SearchRemoteDatasourceImpl(client), HomeRemoteDatasource(client));
          final result = await repository.searchProvidersPage(
              type: type,
              filters: HomeFilters(
                  radioKm: 50,
                  minRating: 4.5,
                  specialtyIds: specialties,
                  sortBy: sort,
                  lat: 10.48,
                  lon: -66.9),
              page: 2);
          final page =
              result.getOrElse(() => throw StateError('unexpected failure'));
          final params = adapter.request.uri.queryParametersAll;
          expect(params['specialtyIds'] ?? params['specialtyIds[]'] ?? [],
              specialties);
          expect(params['radiusKm'], ['50']);
          expect(params['minRating'], ['4.5']);
          expect(params['orderBy'],
              [sort == SortOption.cercania ? 'distancia' : 'rating']);
          expect(params['page'], ['2']);
          expect(params['pageSize'], ['20']);
          expect(params['lat'], ['10.48']);
          expect(params['lng'], ['-66.9']);
          expect(
              adapter.request.path,
              contains(
                  type == ServiceType.workshops ? 'workshops' : 'mechanics'));
          expect(page.items.single.reviews, 37);
          expect(page.items.single.especialidades, ['Frenos']);
          expect(page.total, 41);
        });
      }
    }
  }
}
