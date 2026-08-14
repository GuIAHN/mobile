import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/network/api_endpoints.dart';
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

  test('fetches only the requested page of unread notifications', () async {
    final client = _MockDioClient();
    when(
      () => client.get<List<dynamic>>(
        ApiEndpoints.notifications,
        queryParameters: const {
          'leido': false,
          'page': 2,
          'limit': 20,
        },
      ),
    ).thenAnswer(
      (_) async => Response<List<dynamic>>(
        requestOptions: RequestOptions(path: ApiEndpoints.notifications),
        statusCode: 200,
        data: const [
          {
            '_id': 'n-1',
            'tipo': 'message.new',
            'titulo': 'Mensaje',
            'cuerpo': 'Hola',
            'data': {'conversationId': 'c-1'},
            'leido': false,
            'createdAt': '2026-08-14T12:00:00.000Z',
          },
        ],
      ),
    );
    final datasource = NotificationsRemoteDatasource(client);

    final result = await datasource.getUnreadNotifications(page: 2);

    expect(result, hasLength(1));
    expect(result.single.id, 'n-1');
    expect(result.single.type, 'message.new');
    verify(
      () => client.get<List<dynamic>>(
        ApiEndpoints.notifications,
        queryParameters: const {
          'leido': false,
          'page': 2,
          'limit': 20,
        },
      ),
    ).called(1);
  });

  test('marks one or all notifications read with the exact PATCH routes',
      () async {
    final client = _MockDioClient();
    when(
      () => client.patch<Map<String, dynamic>>(
        ApiEndpoints.notificationRead('n-1'),
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(
          path: ApiEndpoints.notificationRead('n-1'),
        ),
        statusCode: 200,
        data: const {'_id': 'n-1', 'leido': true},
      ),
    );
    when(
      () => client.patch<Map<String, dynamic>>(
        ApiEndpoints.notificationsReadAll,
      ),
    ).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(
          path: ApiEndpoints.notificationsReadAll,
        ),
        statusCode: 200,
        data: const {'success': true},
      ),
    );
    final datasource = NotificationsRemoteDatasource(client);

    await datasource.markRead('n-1');
    await datasource.markAllRead();

    verify(
      () => client.patch<Map<String, dynamic>>(
        ApiEndpoints.notificationRead('n-1'),
      ),
    ).called(1);
    verify(
      () => client.patch<Map<String, dynamic>>(
        ApiEndpoints.notificationsReadAll,
      ),
    ).called(1);
  });
}
