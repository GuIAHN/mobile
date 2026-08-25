import '../../domain/entities/review.dart';

class ReviewModel extends Review {
  const ReviewModel({
    required super.id,
    required super.authorId,
    required super.targetId,
    super.conversationId,
    required super.rating,
    super.comentario,
    required super.createdAt,
    required super.authorName,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'];
    final rawAuthorId = json['authorId'] ?? json['author_id'];
    final rawTargetId = json['targetId'] ?? json['target_id'];
    final rawConversationId = json['conversationId'] ?? json['conversation_id'];
    final rawCreatedAt = json['createdAt'] ?? json['created_at'];

    return ReviewModel(
      id: rawId?.toString() ?? '',
      authorId: rawAuthorId?.toString() ?? '',
      targetId: rawTargetId?.toString() ?? '',
      conversationId: rawConversationId?.toString(),
      rating: json['rating'] is num
          ? (json['rating'] as num).toInt()
          : int.tryParse(json['rating']?.toString() ?? '0') ?? 0,
      comentario: json['comentario']?.toString(),
      createdAt: rawCreatedAt != null
          ? DateTime.tryParse(rawCreatedAt.toString()) ?? DateTime.now()
          : DateTime.now(),
      authorName: (json['authorName'] ?? json['author_name'])?.toString() ??
          'Usuario anónimo',
    );
  }
}
