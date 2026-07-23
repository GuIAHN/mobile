import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/repositories/reviews_repository.dart';
import '../models/review_model.dart';

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
    required String conversationId,
    required int rating,
    String? comentario,
  }) async {
    final response = await _dioClient.post(
      '/reviews',
      data: {
        'conversationId': conversationId,
        'rating': rating,
        if (comentario != null && comentario.isNotEmpty) 'comentario': comentario,
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
}
