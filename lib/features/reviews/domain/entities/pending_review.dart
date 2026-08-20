import 'package:equatable/equatable.dart';

class PendingReview extends Equatable {
  final String targetId;
  final String providerProfileId;
  final String providerName;
  final String? providerPhoto;
  final DateTime? eligibleAt;
  final String conversationId;

  const PendingReview({
    required this.targetId,
    required this.providerProfileId,
    required this.providerName,
    this.providerPhoto,
    this.eligibleAt,
    required this.conversationId,
  });

  @override
  List<Object?> get props => [
        targetId,
        providerProfileId,
        providerName,
        providerPhoto,
        eligibleAt,
        conversationId,
      ];
}
