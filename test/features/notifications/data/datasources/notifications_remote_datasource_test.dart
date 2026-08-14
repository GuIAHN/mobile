import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/network/dio_client.dart';
import 'package:guiautomotriz_mobile/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';

class _MockDioClient extends Mock implements DioClient {}

void main() {
  test('fetches the authenticated unread notification count', () async {
    final client = _MockDioClient();
    when(
      () => client.get<Map<String, dynamic>>(
        'me/notifications/unread-count',
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(
          path: 'me/notifications/unread-count',
        ),
        statusCode: 200,
        data: const {'count': 7},
      ),
    );
    final datasource = NotificationsRemoteDatasource(client);

    final result = await datasource.getUnreadCount();

    expect(result, 7);
    verify(
      () => client.get<Map<String, dynamic>>(
        'me/notifications/unread-count',
      ),
    ).called(1);
    verifyNoMoreInteractions(client);
  });

  test('normalizes string and missing notification counts', () async {
    final client = _MockDioClient();
    final responses = <Map<String, dynamic>>[
      {'count': '12'},
      {},
    ];
    when(
      () => client.get<Map<String, dynamic>>(
        'me/notifications/unread-count',
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(
          path: 'me/notifications/unread-count',
        ),
        statusCode: 200,
        data: responses.removeAt(0),
      ),
    );
    final datasource = NotificationsRemoteDatasource(client);

    expect(await datasource.getUnreadCount(), 12);
    expect(await datasource.getUnreadCount(), 0);
  });
}
