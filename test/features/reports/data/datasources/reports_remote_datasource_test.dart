import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/network/api_endpoints.dart';
import 'package:guiautomotriz_mobile/core/network/dio_client.dart';
import 'package:guiautomotriz_mobile/features/reports/data/datasources/reports_remote_datasource.dart';
import 'package:guiautomotriz_mobile/features/reports/domain/entities/store_dashboard.dart';
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

  test('fetches the M-T06 gross sales metric for the store card', () async {
    final client = _MockDioClient();
    const query = {'from': '2026-08-01', 'to': '2026-08-20'};
    when(
      () => client.get<Map<String, dynamic>>(
        ApiEndpoints.storeMetric('M-T06'),
        queryParameters: query,
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(
          path: ApiEndpoints.storeMetric('M-T06'),
        ),
        statusCode: 200,
        data: const {
          'id': 'M-T06',
          'title': 'Ventas brutas (GMV)',
          'unit': 'currency_hnl',
          'availability': 'AVAILABLE',
          'payload': {'value': 1540.75, 'deltaPct': 12.5},
        },
      ),
    );
    final datasource = ReportsRemoteDataSourceImpl(client);

    final result = await datasource.getStoreMetric(
      'M-T06',
      from: '2026-08-01',
      to: '2026-08-20',
    );

    expect(result, isA<MetricResult>());
    expect(result.id, 'M-T06');
    expect(result.payload['value'], 1540.75);

    const cachedDashboard = DashboardResponse(
      scope: 'STORE',
      computedAt: '2026-08-20T11:59:00.000Z',
      groups: [
        DashboardGroup(
          title: 'Ventas',
          panels: [
            DashboardPanel(
              id: 'M-T06',
              span: 8,
              metric: MetricResult(
                id: 'M-T06',
                title: 'Ventas brutas (GMV)',
                unit: 'currency_hnl',
                availability: 'AVAILABLE',
                payload: {'value': 0},
              ),
            ),
          ],
        ),
      ],
    );
    expect(
      cachedDashboard
          .replaceMetric(result)
          .metricById('M-T06')
          ?.payload['value'],
      1540.75,
    );

    verify(
      () => client.get<Map<String, dynamic>>(
        ApiEndpoints.storeMetric('M-T06'),
        queryParameters: query,
      ),
    ).called(1);
    verifyNoMoreInteractions(client);
  });
}
