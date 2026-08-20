import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/network/dio_client.dart';
import 'package:guiautomotriz_mobile/features/reviews/data/datasources/reviews_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';

class _MockDioClient extends Mock implements DioClient {}

void main() {
  test('maps delivered store review prompts', () async {
    final client = _MockDioClient();
    when(() => client.get('/reviews/pending')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/reviews/pending'),
        data: {
          'items': [
            {
              'targetId': 'store-user-1',
              'providerProfileId': 'store-1',
              'providerName': 'Repuestos Centro',
              'providerPhoto': null,
              'eligibleAt': '2026-08-20T12:00:00.000Z',
              'conversationId': 'conversation-1',
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
}
