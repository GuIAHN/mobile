import 'package:equatable/equatable.dart';
import 'review.dart';

class MyReviewStatus extends Equatable {
  final bool hasReviewed;
  final Review? review;

  const MyReviewStatus({required this.hasReviewed, this.review});

  @override
  List<Object?> get props => [hasReviewed, review];
}
