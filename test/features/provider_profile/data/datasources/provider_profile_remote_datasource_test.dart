import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/network/api_endpoints.dart';
import 'package:guiautomotriz_mobile/core/network/dio_client.dart';
import 'package:guiautomotriz_mobile/features/provider_profile/data/datasources/provider_profile_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';

class _MockDioClient extends Mock implements DioClient {}

void main() {
  late _MockDioClient client;
  late ProviderProfileRemoteDataSource dataSource;

  setUp(() {
    client = _MockDioClient();
    dataSource = ProviderProfileRemoteDataSource(client);
  });

  test('loads the authenticated provider specialties', () async {
    when(
      () => client.get<List<dynamic>>(ApiEndpoints.mechanicSpecialties),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(
          path: ApiEndpoints.mechanicSpecialties,
        ),
        statusCode: 200,
        data: const [
          {'id': 'specialty-1', 'name': 'Mecánica general'},
          {'id': 'specialty-2', 'name': 'Frenos'},
        ],
      ),
    );

    final result = await dataSource.getOwnSpecialties();

    expect(result.map((item) => item.name), ['Mecánica general', 'Frenos']);
    verify(
      () => client.get<List<dynamic>>(ApiEndpoints.mechanicSpecialties),
    ).called(1);
    verifyNoMoreInteractions(client);
  });

  test('replaces all specialties with one profile patch', () async {
    const ids = ['specialty-2', 'specialty-3'];
    when(
      () => client.patch<Map<String, dynamic>>(
        ApiEndpoints.mechanicProfile,
        data: {'specialtyIds': ids},
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ApiEndpoints.mechanicProfile),
        statusCode: 200,
        data: const {
          'id': 'profile-1',
          'specialties': [
            {'id': 'specialty-2', 'name': 'Frenos'},
            {'id': 'specialty-3', 'name': 'Electricidad'},
          ],
        },
      ),
    );

    final result = await dataSource.updateOwnSpecialties(ids);

    expect(result.map((item) => item.id), ids);
    verify(
      () => client.patch<Map<String, dynamic>>(
        ApiEndpoints.mechanicProfile,
        data: {'specialtyIds': ids},
      ),
    ).called(1);
    verifyNoMoreInteractions(client);
  });
}
