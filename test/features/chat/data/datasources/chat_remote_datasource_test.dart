import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/user_role.dart';
import 'package:guiautomotriz_mobile/core/network/api_endpoints.dart';
import 'package:guiautomotriz_mobile/core/network/dio_client.dart';
import 'package:guiautomotriz_mobile/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';

class _MockDioClient extends Mock implements DioClient {}

void main() {
  test('offer card uses the latest chat message and its timestamp', () async {
    final client = _MockDioClient();
    final endpoint = ApiEndpoints.searchOffers('request-1');
    when(() => client.get(endpoint)).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: endpoint),
        statusCode: 200,
        data: const [
          {
            'id': 'offer-1',
            'message': 'Mensaje inicial de la oferta',
            'lastMessage': 'Este es el último mensaje no leído',
            'unreadCount': 2,
            'createdAt': '2026-08-20T12:00:00.000Z',
            'lastMessageAt': '2026-08-20T12:05:00.000Z',
            'status': 'SENT',
            'price': 125,
            'store': {'name': 'Repuestos Central'},
          },
        ],
      ),
    );
    final dataSource = ChatRemoteDataSource(client, () => 'consumer-1');

    final result = await dataSource.getConversations(
      'request-1',
      UserRole.consumer,
    );

    expect(result.single.lastMessage, 'Este es el último mensaje no leído');
    expect(
      result.single.lastMessageAt,
      DateTime.parse('2026-08-20T12:05:00.000Z'),
    );
    expect(result.single.note, 'Mensaje inicial de la oferta');
    expect(result.single.unreadCount, 2);
  });

  test('offer card remains compatible with the previous API contract',
      () async {
    final client = _MockDioClient();
    final endpoint = ApiEndpoints.searchOffers('request-1');
    when(() => client.get(endpoint)).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: endpoint),
        statusCode: 200,
        data: const [
          {
            'id': 'offer-1',
            'message': 'Vista previa heredada',
            'createdAt': '2026-08-20T12:00:00.000Z',
            'status': 'SENT',
            'price': 125,
            'store': {'name': 'Repuestos Central'},
          },
        ],
      ),
    );
    final dataSource = ChatRemoteDataSource(client, () => 'consumer-1');

    final result = await dataSource.getConversations(
      'request-1',
      UserRole.consumer,
    );

    expect(result.single.lastMessage, 'Vista previa heredada');
    expect(
      result.single.lastMessageAt,
      DateTime.parse('2026-08-20T12:00:00.000Z'),
    );
  });
}
