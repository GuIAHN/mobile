import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/error/exceptions.dart';
import 'package:guiautomotriz_mobile/core/error/failures.dart';
import 'package:guiautomotriz_mobile/shared/location/data/datasources/places_remote_datasource.dart';
import 'package:guiautomotriz_mobile/shared/location/data/models/places_search_response_model.dart';
import 'package:guiautomotriz_mobile/shared/location/data/repositories/places_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _MockPlacesRemoteDataSource extends Mock
    implements PlacesRemoteDataSource {}

void main() {
  late _MockPlacesRemoteDataSource remoteDataSource;
  late PlacesRepositoryImpl repository;

  setUp(() {
    remoteDataSource = _MockPlacesRemoteDataSource();
    repository = PlacesRepositoryImpl(remoteDataSource);
  });

  test('returns the domain response from the remote adapter', () async {
    const response = PlacesSearchResponseModel(results: []);
    when(() => remoteDataSource.search('Tegucigalpa'))
        .thenAnswer((_) async => response);

    final result = await repository.search('Tegucigalpa');

    expect(
        result.getOrElse(() => throw StateError('Expected success')), response);
  });

  test('maps malformed external data to a domain ParseFailure', () async {
    when(() => remoteDataSource.search('Tegucigalpa'))
        .thenThrow(const ParseException());

    final result = await repository.search('Tegucigalpa');

    expect(result.fold((failure) => failure, (_) => null), isA<ParseFailure>());
  });
}
