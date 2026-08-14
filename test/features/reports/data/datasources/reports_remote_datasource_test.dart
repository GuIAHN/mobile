import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/network/api_endpoints.dart';
import 'package:guiautomotriz_mobile/core/network/dio_client.dart';
import 'package:guiautomotriz_mobile/features/reports/data/datasources/reports_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';

class _MockDioClient extends Mock implements DioClient {}

void main() {
  test('fetches the authenticated mechanic or workshop dashboard', () async {
    final client = _MockDioClient();
    const query = {'from': '2026-08-01', 'to': '2026-08-14'};
    when(
      () => client.get<Map<String, dynamic>>(
        ApiEndpoints.providerDashboard,
        queryParameters: query,
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ApiEndpoints.providerDashboard),
        statusCode: 200,
        data: const {
          'scope': 'MECHANIC',
          'computedAt': '2026-08-14T12:00:00.000Z',
          'groups': [],
        },
      ),
    );
    final datasource = ReportsRemoteDataSourceImpl(client);

    final result = await datasource.getProviderDashboard(
      from: '2026-08-01',
      to: '2026-08-14',
    );

    expect(result.scope, 'MECHANIC');
    verify(
      () => client.get<Map<String, dynamic>>(
        ApiEndpoints.providerDashboard,
        queryParameters: query,
      ),
    ).called(1);
    verifyNoMoreInteractions(client);
  });
}
