import 'package:equatable/equatable.dart';

class PendingReview extends Equatable {
  final String targetId;
  final String providerProfileId;
  final String providerName;
  final String? providerPhoto;
  final DateTime? eligibleAt;
  final String? conversationId;
  final bool hasReviewed;
  final String? reviewId;
  final int? reviewRating;
  final String? reviewComment;

  const PendingReview({
    required this.targetId,
    required this.providerProfileId,
    required this.providerName,
    this.providerPhoto,
    this.eligibleAt,
    this.conversationId,
    this.hasReviewed = false,
    this.reviewId,
    this.reviewRating,
    this.reviewComment,
  });

  @override
  List<Object?> get props => [
        targetId,
        providerProfileId,
        providerName,
        providerPhoto,
        eligibleAt,
        conversationId,
        hasReviewed,
        reviewId,
        reviewRating,
        reviewComment,
      ];
}
