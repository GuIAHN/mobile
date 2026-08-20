import '../../../../core/network/dio_client.dart';
import '../../domain/repositories/reviews_repository.dart';
import '../models/review_model.dart';
import '../models/pending_review_model.dart';
import '../../domain/entities/my_review_status.dart';

class ReviewsRemoteDataSource {
  final DioClient _dioClient;

  ReviewsRemoteDataSource(this._dioClient);

  Future<PaginatedReviews> getReviewsByTarget(
    String targetId, {
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _dioClient.get(
      '/users/$targetId/reviews',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    final data = response.data;
    final items = (data['items'] as List)
        .map((json) => ReviewModel.fromJson(json as Map<String, dynamic>))
        .toList();

    return PaginatedReviews(
      items: items,
      total: data['total'] as int,
      page: data['page'] as int,
      limit: data['limit'] as int,
      totalPages: data['totalPages'] as int,
    );
  }

  Future<ReviewModel> createReview({
    String? conversationId,
    String? targetId,
    required int rating,
    String? comentario,
  }) async {
    final response = await _dioClient.post(
      '/reviews',
      data: {
        if (conversationId != null) 'conversationId': conversationId,
        if (targetId != null) 'targetId': targetId,
        'rating': rating,
        if (comentario != null && comentario.isNotEmpty)
          'comentario': comentario,
      },
    );
    final rawData = response.data;
    final Map<String, dynamic> json;
    if (rawData is Map<String, dynamic>) {
      json = rawData;
    } else if (rawData is Map) {
      json = Map<String, dynamic>.from(rawData);
    } else {
      // Success response but non-parseable body – return a minimal stub
      return ReviewModel(
        id: '',
        authorId: '',
        targetId: '',
        conversationId: conversationId,
        rating: rating,
        comentario: comentario,
        createdAt: DateTime.now(),
        authorName: 'Usuario anónimo',
      );
    }
    return ReviewModel.fromJson(json);
  }

  Future<ReviewModel> updateReview(
    String id, {
    int? rating,
    String? comentario,
  }) async {
    final response = await _dioClient.patch(
      '/reviews/$id',
      data: {
        if (rating != null) 'rating': rating,
        if (comentario != null) 'comentario': comentario,
      },
    );
    return ReviewModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteReview(String id) async {
    await _dioClient.delete('/reviews/$id');
  }

  Future<List<PendingReviewModel>> getPendingReviews() async {
    final response = await _dioClient.get('/reviews/pending');
    final data = response.data as Map<String, dynamic>;
    return (data['items'] as List? ?? const [])
        .map((item) => PendingReviewModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .where((item) =>
            item.targetId.isNotEmpty && item.conversationId.isNotEmpty)
        .toList();
  }

  Future<MyReviewStatus> getMyReview(String targetId) async {
    final response = await _dioClient.get('/reviews/mine/$targetId');
    final data = Map<String, dynamic>.from(response.data as Map);
    final reviewData = data['review'];
    if (data['hasReviewed'] != true || reviewData is! Map) {
      return const MyReviewStatus(hasReviewed: false);
    }
    final json = Map<String, dynamic>.from(reviewData);
    json['targetId'] = targetId;
    return MyReviewStatus(
      hasReviewed: true,
      review: ReviewModel.fromJson(json),
    );
  }

  Future<void> trackProviderContact(
    String providerProfileId,
    String channel,
  ) async {
    await _dioClient.post(
      '/providers/$providerProfileId/contact-clicks',
      data: {'channel': channel},
    );
  }
}
