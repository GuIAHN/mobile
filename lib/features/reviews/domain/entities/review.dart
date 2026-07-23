import 'package:equatable/equatable.dart';

class Review extends Equatable {
  final String id;
  final String authorId;
  final String targetId;
  final String conversationId;
  final int rating;
  final String? comentario;
  final DateTime createdAt;
  final String authorName;

  const Review({
    required this.id,
    required this.authorId,
    required this.targetId,
    required this.conversationId,
    required this.rating,
    this.comentario,
    required this.createdAt,
    required this.authorName,
  });

  @override
  List<Object?> get props => [
        id,
        authorId,
        targetId,
        conversationId,
        rating,
        comentario,
        createdAt,
        authorName,
      ];
}
