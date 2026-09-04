import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/user_role.dart';
import 'package:guiautomotriz_mobile/core/network/api_endpoints.dart';
import 'package:guiautomotriz_mobile/core/network/dio_client.dart';
import 'package:guiautomotriz_mobile/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';

class _MockDioClient extends Mock implements DioClient {}

void main() {
  test('reads offers from the new paginated response envelope', () async {
    final client = _MockDioClient();
    final endpoint = ApiEndpoints.searchOffers('request-paginated');
    when(() => client.get(endpoint)).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: endpoint),
        statusCode: 200,
        data: const {
          'items': [
            {
              'id': 'offer-1',
              'createdAt': '2026-08-30T12:00:00.000Z',
              'status': 'SENT',
              'price': 100,
              'store': {'name': 'Tienda 01'},
            },
          ],
          'total': 1,
          'page': 1,
          'pageSize': 50,
          'counts': {'all': 1, 'quotes': 1, 'questions': 0},
        },
      ),
    );
    final dataSource = ChatRemoteDataSource(client, () => 'consumer-1');

    final result = await dataSource.getConversations(
      'request-paginated',
      UserRole.consumer,
    );

    expect(result.single.offerId, 'offer-1');
    expect(result.single.price, 100);
  });

  test('loads only the latest message and resolves its authorship', () async {
    final client = _MockDioClient();
    const endpoint = 'conversations/conversation-1/messages?limit=1';
    when(() => client.get(endpoint)).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: endpoint),
        statusCode: 200,
        data: const [
          {
            '_id': 'message-1',
            'conversationId': 'conversation-1',
            'senderId': 'consumer-1',
            'senderName': 'Carlos',
            'content': 'Ya lo revisé',
            'type': 'text',
            'createdAt': '2026-08-20T12:05:00.000Z',
            'read': true,
          },
        ],
      ),
    );
    final dataSource = ChatRemoteDataSource(client, () => 'consumer-1');

    final result = await dataSource.getLatestMessage('conversation-1');

    expect(result?.content, 'Ya lo revisé');
    expect(result?.isFromMe, isTrue);
    expect(result?.isRead, isTrue);
    verify(() => client.get(endpoint)).called(1);
  });

  test('keeps latest-message authorship after the conversation is read',
      () async {
    final client = _MockDioClient();
    when(() => client.get('conversations/me')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: 'conversations/me'),
        statusCode: 200,
        data: const [
          {
            'id': 'conversation-1',
            'offerId': 'offer-1',
            'participantName': 'Repuestos Central',
            'lastMessage': 'Ya lo revisé',
            'lastMessageSenderId': 'consumer-1',
            'unreadCount': 0,
            'lastMessageAt': '2026-08-20T12:05:00.000Z',
            'hasQuote': true,
            'price': 125,
            'deliveryCost': 25,
            'totalCost': 150,
          },
        ],
      ),
    );
    final dataSource = ChatRemoteDataSource(client, () => 'consumer-1');

    final result = await dataSource.getMyConversations();

    expect(result.single.unreadCount, 0);
    expect(result.single.lastMessageIsFromMe, isTrue);
    expect(result.single.price, 125);
    expect(result.single.deliveryCost, 25);
    expect(result.single.totalCost, 150);
  });

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
            'conversationId': 'conversation-1',
            'message': 'Mensaje inicial de la oferta',
            'lastMessage': 'Este es el último mensaje no leído',
            'unreadCount': 2,
            'createdAt': '2026-08-20T12:00:00.000Z',
            'lastMessageAt': '2026-08-20T12:05:00.000Z',
            'status': 'SENT',
            'price': 125,
            'deliveryCost': 25,
            'totalCost': 150,
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
    expect(result.single.conversationId, 'conversation-1');
    expect(
      result.single.lastMessageAt,
      DateTime.parse('2026-08-20T12:05:00.000Z'),
    );
    expect(result.single.note, 'Mensaje inicial de la oferta');
    expect(result.single.unreadCount, 2);
    expect(result.single.deliveryCost, 25);
    expect(result.single.totalCost, 150);
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

  test('reads cancellation metadata and store reputation from offers',
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
            'createdAt': '2026-08-20T12:00:00.000Z',
            'status': 'CANCELLED',
            'cancelledAt': '2026-08-22T09:00:00.000Z',
            'cancelSource': 'SYSTEM',
            'cancelReason': 'Sin confirmación de entrega',
            'cancelReasonCode': 'SIN_CONFIRMACION_ENTREGA',
            'price': 125,
            'store': {
              'name': 'Repuestos Central',
              'rating': 4.6,
              'ratingCount': 18,
            },
          },
        ],
      ),
    );
    final dataSource = ChatRemoteDataSource(client, () => 'consumer-1');

    final offer = (await dataSource.getConversations(
      'request-1',
      UserRole.consumer,
    ))
        .single;

    expect(offer.offerStatus, 'CANCELLED');
    expect(offer.cancelSource, 'SYSTEM');
    expect(offer.cancelReason, 'Sin confirmación de entrega');
    expect(offer.cancelReasonCode, 'SIN_CONFIRMACION_ENTREGA');
    expect(offer.storeRating, 4.6);
    expect(offer.storeReviewCount, 18);
  });

  test('reads flat reputation fields from the conversations inbox', () async {
    final client = _MockDioClient();
    when(() => client.get('conversations/me')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: 'conversations/me'),
        statusCode: 200,
        data: const [
          {
            'id': 'conversation-1',
            'participantName': 'Tienda RC-A1B2C3',
            'storeRating': 4.5,
            'storeRatingCount': 12,
          },
        ],
      ),
    );
    final dataSource = ChatRemoteDataSource(client, () => 'consumer-1');

    final conversation = (await dataSource.getMyConversations()).single;

    expect(conversation.storeRating, 4.5);
    expect(conversation.storeReviewCount, 12);
  });

  test('reads inquiry decline metadata from conversation details', () async {
    final client = _MockDioClient();
    when(() => client.get('conversations/conversation-1')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: 'conversations/conversation-1'),
        statusCode: 200,
        data: const {
          'id': 'conversation-1',
          'offerId': 'offer-1',
          'offerStatus': 'INQUIRY',
          'searchMatchId': 'match-1',
          'declinedAt': '2026-08-24T12:00:00.000Z',
          'declineReason': 'SIN_STOCK',
          'isInquiry': true,
          'subcategoryName': 'Otro',
          'subcategoryIsCatchAll': true,
          'category': {'id': 'frenos', 'name': 'Frenos'},
        },
      ),
    );
    final dataSource = ChatRemoteDataSource(client, () => 'store-1');

    final conversation =
        await dataSource.getConversationDetails('conversation-1');

    expect(conversation.searchMatchId, 'match-1');
    expect(
      conversation.declinedAt,
      DateTime.parse('2026-08-24T12:00:00.000Z'),
    );
    expect(conversation.declineReason, 'SIN_STOCK');
    expect(conversation.subcategoryName, 'Otro');
    expect(conversation.subcategoryIsCatchAll, isTrue);
    expect(conversation.categoryId, 'frenos');
    expect(conversation.categoryName, 'Frenos');
  });

  test('uses the cancellation and decline endpoints', () async {
    final client = _MockDioClient();
    final dataSource = ChatRemoteDataSource(client, () => 'consumer-1');
    when(
      () => client.post(
        ApiEndpoints.offerCancel('offer-1'),
        data: {'reason': 'Ya no lo necesito'},
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: 'offers/offer-1/cancel'),
      ),
    );
    when(
      () => client.post(
        ApiEndpoints.offerCancelSale('offer-2'),
        data: {
          'reasonCode': 'OTRO',
          'note': 'El local estará cerrado',
        },
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: 'offers/offer-2/cancel-sale'),
      ),
    );
    when(
      () => client.post(
        ApiEndpoints.storeSearchRequestDecline('match-1'),
        data: {'reason': 'SIN_STOCK'},
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: 'decline'),
      ),
    );
    when(
      () => client.delete(
        ApiEndpoints.storeSearchRequestDecline('match-1'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: 'decline'),
      ),
    );

    await dataSource.cancelOffer('offer-1', reason: 'Ya no lo necesito');
    await dataSource.cancelSaleByStore(
      'offer-2',
      reasonCode: 'OTRO',
      note: 'El local estará cerrado',
    );
    await dataSource.declineMatch('match-1', 'SIN_STOCK');
    await dataSource.undoDecline('match-1');

    verify(
      () => client.post(
        ApiEndpoints.offerCancel('offer-1'),
        data: {'reason': 'Ya no lo necesito'},
      ),
    ).called(1);
    verify(
      () => client.post(
        ApiEndpoints.offerCancelSale('offer-2'),
        data: {
          'reasonCode': 'OTRO',
          'note': 'El local estará cerrado',
        },
      ),
    ).called(1);
    verify(
      () => client.post(
        ApiEndpoints.storeSearchRequestDecline('match-1'),
        data: {'reason': 'SIN_STOCK'},
      ),
    ).called(1);
    verify(
      () => client.delete(
        ApiEndpoints.storeSearchRequestDecline('match-1'),
      ),
    ).called(1);
  });

  test('updates delivery cost and can explicitly clear it', () async {
    final client = _MockDioClient();
    final dataSource = ChatRemoteDataSource(client, () => 'store-1');
    when(
      () => client.patch(
        'offers/offer-1',
        data: {'price': 125.0, 'deliveryCost': 24.5},
      ),
    ).thenAnswer(
      (_) async => Response(requestOptions: RequestOptions(path: 'offer')),
    );
    when(
      () => client.patch(
        'offers/offer-1',
        data: {'price': 125.0, 'deliveryCost': null},
      ),
    ).thenAnswer(
      (_) async => Response(requestOptions: RequestOptions(path: 'offer')),
    );

    await dataSource.quoteOffer(
      offerId: 'offer-1',
      price: 125,
      updateDeliveryCost: true,
      deliveryCost: 24.5,
    );
    await dataSource.quoteOffer(
      offerId: 'offer-1',
      price: 125,
      updateDeliveryCost: true,
      deliveryCost: null,
    );

    verify(
      () => client.patch(
        'offers/offer-1',
        data: {'price': 125.0, 'deliveryCost': 24.5},
      ),
    ).called(1);
    verify(
      () => client.patch(
        'offers/offer-1',
        data: {'price': 125.0, 'deliveryCost': null},
      ),
    ).called(1);
  });

  test('store conversations return empty without downloading the inbox',
      () async {
    final client = _MockDioClient();
    final dataSource = ChatRemoteDataSource(client, () => 'store-1');

    final result =
        await dataSource.getConversations('request-1', UserRole.store);

    expect(result, isEmpty);
    verifyNever(() => client.get(any()));
  });

  test('creates a quote with the known match without refetching sales',
      () async {
    final client = _MockDioClient();
    final dataSource = ChatRemoteDataSource(client, () => 'store-1');
    when(
      () => client.post(
        'offers',
        data: {'searchMatchId': 'match-1', 'price': 100.0},
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: 'offers'),
        data: const {
          'id': 'offer-1',
          'conversationId': 'conversation-1',
          'message': '',
          'createdAt': '2026-08-24T12:00:00.000Z',
          'status': 'SENT',
          'price': 100,
        },
      ),
    );

    final result = await dataSource.createQuote(
      threadId: 'request-1',
      searchMatchId: 'match-1',
      price: 100,
    );

    expect(result.searchMatchId, 'match-1');
    verifyNever(() => client.get(any()));
    verify(
      () => client.post(
        'offers',
        data: {'searchMatchId': 'match-1', 'price': 100.0},
      ),
    ).called(1);
  });

  test('keeps the sales lookup as create-quote fallback', () async {
    final client = _MockDioClient();
    final dataSource = ChatRemoteDataSource(client, () => 'store-1');
    const fallbackEndpoint =
        '${ApiEndpoints.storeSearchRequests}?status=ALL&page=1&pageSize=100';
    when(() => client.get(fallbackEndpoint)).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: fallbackEndpoint),
        data: const {
          'items': [
            {'id': 'request-1', 'searchMatchId': 'match-fallback'},
          ],
        },
      ),
    );
    when(
      () => client.post(
        'offers',
        data: {'searchMatchId': 'match-fallback'},
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: 'offers'),
        data: const {
          'id': 'offer-1',
          'conversationId': 'conversation-1',
          'message': '',
          'createdAt': '2026-08-24T12:00:00.000Z',
          'status': 'INQUIRY',
        },
      ),
    );

    final result = await dataSource.createQuote(threadId: 'request-1');

    expect(result.searchMatchId, 'match-fallback');
    verify(() => client.get(fallbackEndpoint)).called(1);
  });

  test('loads a store request detail by id and maps the nested offer',
      () async {
    final client = _MockDioClient();
    final endpoint = ApiEndpoints.storeSearchRequestDetail('request-1');
    when(() => client.get(endpoint)).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: endpoint),
        statusCode: 200,
        data: const {
          'id': 'request-1',
          'searchMatchId': 'match-1',
          'matchState': 'INQUIRING',
          'vehicle': {
            'brand': 'Audi',
            'model': '80',
            'year': 1992,
          },
          'subcategory': {
            'id': 'subcategory-1',
            'name': 'Otro',
            'isCatchAll': true,
            'parent': {'id': 'electricidad', 'name': 'Electricidad'},
          },
          'consumerName': 'Carlos',
          'createdAt': '2026-09-03T12:00:00.000Z',
          'lastMessageAt': '2026-09-03T12:05:00.000Z',
          'expiresAt': '2026-09-05T12:00:00.000Z',
          'requestStatus': 'OPEN',
          'isExpired': false,
          'conversationId': 'conversation-1',
          'myOffer': {
            'id': 'offer-1',
            'status': 'INQUIRY',
            'price': null,
            'deliveryCost': 5,
            'totalCost': 5,
          },
        },
      ),
    );
    final dataSource = ChatRemoteDataSource(client, () => 'store-1');

    final result =
        await dataSource.getRequestDetail('request-1', UserRole.store);

    expect(result.title, 'Audi 80');
    expect(result.subcategory, 'Otro');
    expect(result.subcategoryId, 'subcategory-1');
    expect(result.subcategoryIsCatchAll, isTrue);
    expect(result.categoryId, 'electricidad');
    expect(result.categoryName, 'Electricidad');
    expect(result.searchMatchId, 'match-1');
    expect(result.offerId, 'offer-1');
    expect(result.conversationId, 'conversation-1');
    expect(result.isInquiryState, isTrue);
    expect(result.deliveryCost, 5);
    verify(() => client.get(endpoint)).called(1);
  });

  test('store title fallback never exposes a catch-all stored name', () async {
    final client = _MockDioClient();
    final endpoint = ApiEndpoints.storeSearchRequestDetail('request-no-car');
    when(() => client.get(endpoint)).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: endpoint),
        statusCode: 200,
        data: const {
          'id': 'request-no-car',
          'subcategory': {
            'id': 'misc',
            'name': 'Nombre administrativo variable',
            'isCatchAll': true,
            'parent': {'id': 'electricidad', 'name': 'Electricidad'},
          },
          'createdAt': '2026-09-03T12:00:00.000Z',
          'requestStatus': 'OPEN',
        },
      ),
    );
    final dataSource = ChatRemoteDataSource(client, () => 'store-1');

    final result = await dataSource.getRequestDetail(
      'request-no-car',
      UserRole.store,
    );

    expect(
      result.title,
      'Electricidad › Sin categoría exacta — ver descripción',
    );
  });

  test('loads a consumer request detail by id', () async {
    final client = _MockDioClient();
    final endpoint = ApiEndpoints.searchDetail('request-2');
    when(() => client.get(endpoint)).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: endpoint),
        statusCode: 200,
        data: const {
          'id': 'request-2',
          'consumerId': 'consumer-1',
          'vehicle': {
            'model': {
              'name': 'Corolla',
              'brand': {'name': 'Toyota'},
            },
            'year': 2020,
          },
          'subcategory': {
            'id': 'subcategory-2',
            'name': 'Pastillas',
            'isCatchAll': false,
            'parent': {'id': 'frenos', 'name': 'Frenos'},
          },
          'createdAt': '2026-09-03T12:00:00.000Z',
          'expiresAt': '2026-09-05T12:00:00.000Z',
          'status': 'OPEN',
          'isExpired': false,
          'quotesCount': 2,
          'questionsCount': 1,
          'bestOfferPrice': 125,
          'bestOfferStoreName': 'Repuestos Central',
        },
      ),
    );
    final dataSource = ChatRemoteDataSource(client, () => 'consumer-1');

    final result =
        await dataSource.getRequestDetail('request-2', UserRole.consumer);

    expect(result.title, 'Toyota Corolla');
    expect(result.vehicleYear, 2020);
    expect(result.subcategory, 'Pastillas');
    expect(result.subcategoryId, 'subcategory-2');
    expect(result.subcategoryIsCatchAll, isFalse);
    expect(result.categoryId, 'frenos');
    expect(result.categoryName, 'Frenos');
    expect(result.quotesCount, 2);
    expect(result.questionsCount, 1);
    expect(result.bestOfferPrice, 125);
    verify(() => client.get(endpoint)).called(1);
  });
}
