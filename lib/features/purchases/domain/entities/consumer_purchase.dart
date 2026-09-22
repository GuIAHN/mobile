import 'package:equatable/equatable.dart';

enum PurchaseStatus {
  bought,
  delivered,
  cancelled,
  unknown,
}

enum PurchaseFilter {
  all,
  toReceive,
  delivered,
  cancelled,
}

class ConsumerPurchase extends Equatable {
  const ConsumerPurchase({
    required this.id,
    required this.vehicleName,
    required this.storeName,
    required this.status,
    required this.lastActivityAt,
    this.storeId,
    this.photoUrl,
    this.partName,
    this.subcategoryId,
    this.subcategoryIsCatchAll = false,
    this.categoryId,
    this.categoryName,
    this.partType,
    this.vehicleYear,
    this.offerId,
    this.price,
    this.deliveryCost,
    this.totalCost,
    this.conversationId,
    this.cancelledAt,
    this.cancelSource,
    this.cancelReason,
    this.cancelReasonCode,
    this.hasReviewed = false,
    this.needsReview = false,
    this.canReview = false,
    this.reviewTargetId,
  });

  final String id;
  final String vehicleName;
  final String storeName;
  final PurchaseStatus status;
  final DateTime lastActivityAt;
  final String? storeId;
  final String? photoUrl;
  final String? partName;
  final String? subcategoryId;
  final bool subcategoryIsCatchAll;
  final String? categoryId;
  final String? categoryName;
  final String? partType;
  final int? vehicleYear;
  final String? offerId;
  final double? price;
  final double? deliveryCost;
  final double? totalCost;
  final String? conversationId;
  final DateTime? cancelledAt;
  final String? cancelSource;
  final String? cancelReason;
  final String? cancelReasonCode;
  final bool hasReviewed;
  final bool needsReview;
  final bool canReview;
  final String? reviewTargetId;

  double? get resolvedTotal => totalCost ?? price;

  @override
  List<Object?> get props => [
        id,
        vehicleName,
        storeName,
        status,
        lastActivityAt,
        storeId,
        photoUrl,
        partName,
        subcategoryId,
        subcategoryIsCatchAll,
        categoryId,
        categoryName,
        partType,
        vehicleYear,
        offerId,
        price,
        deliveryCost,
        totalCost,
        conversationId,
        cancelledAt,
        cancelSource,
        cancelReason,
        cancelReasonCode,
        hasReviewed,
        needsReview,
        canReview,
        reviewTargetId,
      ];
}
