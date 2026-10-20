import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/network/dio_client.dart';
import 'package:guiautomotriz_mobile/features/reviews/data/datasources/reviews_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';

class _MockDioClient extends Mock implements DioClient {}

void main() {
  test('maps purchase and prompt identifiers', () async {
    final client = _MockDioClient();
    when(() => client.get('/reviews/pending')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/reviews/pending'),
        data: {
          'items': [
            {
              'id': 'prompt-1',
              'offerId': 'offer-1',
              'targetId': 'store-user-1',
              'providerProfileId': 'store-1',
              'providerName': 'Repuestos Centro',
              'providerPhoto': null,
              'eligibleAt': '2026-08-20T12:00:00.000Z',
              'conversationId': 'conversation-1',
              'hasReviewed': false,
              'reviewId': null,
              'reviewRating': null,
              'reviewComment': null,
            },
          ],
          'total': 1,
        },
      ),
    );

    final result = await ReviewsRemoteDataSource(client).getPendingReviews();

    expect(result, hasLength(1));
    expect(result.single.targetId, 'store-user-1');
    expect(result.single.conversationId, 'conversation-1');
    expect(result.single.id, 'prompt-1');
    expect(result.single.offerId, 'offer-1');
  });

  test('keeps actionable provider prompts without a conversation', () async {
    final client = _MockDioClient();
    when(() => client.get('/reviews/pending')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/reviews/pending'),
        data: {
          'items': [
            {
              'targetId': 'mechanic-user-1',
              'providerProfileId': 'mechanic-1',
              'providerName': 'Mecánica Central',
              'hasReviewed': false,
            },
          ],
          'total': 1,
        },
      ),
    );

    final result = await ReviewsRemoteDataSource(client).getPendingReviews();

    expect(result, hasLength(1));
    expect(result.single.conversationId, isNull);
    expect(result.single.hasReviewed, isFalse);
  });

  test('creates direct provider reviews with targetId only', () async {
    final client = _MockDioClient();
    when(
      () => client.post(
        '/reviews',
        data: {
          'targetId': 'mechanic-user-1',
          'rating': 5,
          'comentario': 'Excelente',
        },
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/reviews'),
        data: {
          'id': 'review-1',
          'targetId': 'mechanic-user-1',
          'rating': 5,
          'comentario': 'Excelente',
          'createdAt': '2026-08-20T12:00:00.000Z',
        },
      ),
    );

    final review = await ReviewsRemoteDataSource(client).createReview(
      targetId: 'mechanic-user-1',
      rating: 5,
      comentario: 'Excelente',
    );

    expect(review.rating, 5);
    expect(review.conversationId, isNull);
    verify(
      () => client.post(
        '/reviews',
        data: {
          'targetId': 'mechanic-user-1',
          'rating': 5,
          'comentario': 'Excelente',
        },
      ),
    ).called(1);
  });

  test('creates store reviews with offerId only', () async {
    final client = _MockDioClient();
    when(
      () => client.post(
        '/reviews',
        data: {
          'offerId': 'offer-1',
          'rating': 4,
          'comentario': 'Entrega rápida',
        },
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/reviews'),
        data: {
          '_id': 'review-store-1',
          'author_id': 'consumer-user-1',
          'target_id': 'store-user-1',
          'offer_id': 'offer-1',
          'rating': 4,
          'comentario': 'Entrega rápida',
          'created_at': '2026-08-20T12:00:00.000Z',
        },
      ),
    );

    final review = await ReviewsRemoteDataSource(client).createReview(
      offerId: 'offer-1',
      rating: 4,
      comentario: 'Entrega rápida',
    );

    expect(review.id, 'review-store-1');
    expect(review.targetId, 'store-user-1');
    expect(review.offerId, 'offer-1');
    expect(review.conversationId, isNull);
    expect(review.rating, 4);
    verify(
      () => client.post(
        '/reviews',
        data: {
          'offerId': 'offer-1',
          'rating': 4,
          'comentario': 'Entrega rápida',
        },
      ),
    ).called(1);
  });

  test('maps the current editable review', () async {
    final client = _MockDioClient();
    when(() => client.get('/reviews/mine/store-user-1')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/reviews/mine/store-user-1'),
        data: {
          'hasReviewed': true,
          'review': {
            'id': 'review-1',
            'rating': 4,
            'comentario': 'Muy bien',
            'createdAt': '2026-08-20T12:00:00.000Z',
          },
        },
      ),
    );

    final status =
        await ReviewsRemoteDataSource(client).getMyReview('store-user-1');

    expect(status.hasReviewed, isTrue);
    expect(status.review?.id, 'review-1');
    expect(status.review?.targetId, 'store-user-1');
    expect(status.review?.rating, 4);
  });
  test('queries the review of a specific purchase at the same store', () async {
    final client = _MockDioClient();
    when(() => client.get('/reviews/mine/store-user-1',
        queryParameters: {'offerId': 'offer-2'})).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/reviews/mine/store-user-1'),
        data: {'hasReviewed': false, 'review': null},
      ),
    );
    final status = await ReviewsRemoteDataSource(client)
        .getMyReview('store-user-1', offerId: 'offer-2');
    expect(status.hasReviewed, isFalse);
    verify(() => client.get('/reviews/mine/store-user-1',
        queryParameters: {'offerId': 'offer-2'})).called(1);
  });

  test('rejects missing or mixed review identities before sending', () async {
    final client = _MockDioClient();
    final source = ReviewsRemoteDataSource(client);
    for (final ids in [
      (offerId: null, targetId: null),
      (offerId: 'offer-1', targetId: 'store-user-1'),
      (offerId: ' ', targetId: null),
    ]) {
      await expectLater(
          source.createReview(
            offerId: ids.offerId,
            targetId: ids.targetId,
            rating: 4,
          ),
          throwsArgumentError);
    }
    verifyZeroInteractions(client);
  });

  test('dismisses only the prompt identified by its id', () async {
    final client = _MockDioClient();
    when(() => client.post('/reviews/pending/prompt-2/dismiss')).thenAnswer(
      (_) async => Response(
        requestOptions:
            RequestOptions(path: '/reviews/pending/prompt-2/dismiss'),
        statusCode: 200,
      ),
    );
    await ReviewsRemoteDataSource(client).dismissPendingReview('prompt-2');
    verify(() => client.post('/reviews/pending/prompt-2/dismiss')).called(1);
  });
}
