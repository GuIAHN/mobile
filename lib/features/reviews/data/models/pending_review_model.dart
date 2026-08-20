import '../../domain/entities/pending_review.dart';

class PendingReviewModel extends PendingReview {
  const PendingReviewModel({
    required super.targetId,
    required super.providerProfileId,
    required super.providerName,
    super.providerPhoto,
    super.eligibleAt,
    required super.conversationId,
  });

  factory PendingReviewModel.fromJson(Map<String, dynamic> json) {
    return PendingReviewModel(
      targetId: json['targetId']?.toString() ?? '',
      providerProfileId: json['providerProfileId']?.toString() ?? '',
      providerName: json['providerName']?.toString() ?? 'Tienda',
      providerPhoto: json['providerPhoto']?.toString(),
      eligibleAt: DateTime.tryParse(json['eligibleAt']?.toString() ?? ''),
      conversationId: json['conversationId']?.toString() ?? '',
    );
  }
}
