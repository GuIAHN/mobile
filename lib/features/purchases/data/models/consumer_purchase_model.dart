import '../../domain/entities/consumer_purchase.dart';

class ConsumerPurchaseModel extends ConsumerPurchase {
  const ConsumerPurchaseModel({
    required super.id,
    required super.vehicleName,
    required super.storeName,
    required super.status,
    required super.lastActivityAt,
    super.storeId,
    super.photoUrl,
    super.partName,
    super.partType,
    super.vehicleYear,
    super.offerId,
    super.price,
    super.deliveryCost,
    super.totalCost,
    super.conversationId,
    super.cancelledAt,
    super.cancelSource,
    super.cancelReason,
    super.cancelReasonCode,
    super.hasReviewed,
    super.needsReview,
    super.canReview,
    super.reviewTargetId,
  });

  factory ConsumerPurchaseModel.fromJson(Map<String, dynamic> json) {
    final vehicle = Map<String, dynamic>.from(json['vehicle'] as Map? ?? {});
    final store = Map<String, dynamic>.from(json['store'] as Map? ?? {});
    final brand = vehicle['brand']?.toString() ?? '';
    final model = vehicle['model']?.toString() ?? '';
    final vehicleName = '$brand $model'.trim();
    final activityValue = json['lastMessageAt'] ?? json['boughtAt'];

    return ConsumerPurchaseModel(
      id: json['searchRequestId'] as String,
      vehicleName:
          vehicleName.isEmpty ? 'Vehículo no especificado' : vehicleName,
      storeName: store['name']?.toString() ?? 'Tienda',
      storeId: store['id']?.toString(),
      status: _purchaseStatusFromApi(json['status']?.toString()),
      lastActivityAt: DateTime.tryParse(activityValue?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      photoUrl: (json['sparePhotoUrl'] ?? json['requestPhotoUrl'])?.toString(),
      partName: (json['subcategory'] as Map?)?['name']?.toString(),
      partType: json['partType']?.toString(),
      vehicleYear: (vehicle['year'] as num?)?.toInt(),
      offerId: json['offerId']?.toString(),
      price: (json['price'] as num?)?.toDouble(),
      deliveryCost: (json['deliveryCost'] as num?)?.toDouble(),
      totalCost: (json['totalCost'] as num?)?.toDouble(),
      conversationId: json['conversationId']?.toString(),
      cancelledAt: json['cancelledAt'] == null
          ? null
          : DateTime.tryParse(json['cancelledAt'].toString()),
      cancelSource: json['cancelSource']?.toString(),
      cancelReason:
          (json['cancelReasonLabel'] ?? json['cancelReason'])?.toString(),
      cancelReasonCode: json['cancelReasonCode']?.toString(),
      hasReviewed: json['hasReviewed'] as bool? ?? false,
      needsReview: json['needsReview'] as bool? ?? false,
      canReview: json['canReview'] as bool? ?? false,
      reviewTargetId: store['reviewTargetId']?.toString(),
    );
  }
}

PurchaseStatus _purchaseStatusFromApi(String? value) {
  return switch (value?.toUpperCase()) {
    'BOUGHT' => PurchaseStatus.bought,
    'DELIVERED' => PurchaseStatus.delivered,
    'CANCELLED' => PurchaseStatus.cancelled,
    _ => PurchaseStatus.unknown,
  };
}
