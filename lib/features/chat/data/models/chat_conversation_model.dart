import '../../domain/entities/chat_conversation.dart';

class ChatConversationModel extends ChatConversation {
  const ChatConversationModel({
    required super.id,
    super.conversationId,
    required super.threadId,
    required super.participantName,
    super.participantAvatarUrl,
    required super.lastMessage,
    required super.unreadCount,
    required super.lastMessageAt,
    super.offerId,
    super.offerStatus,
    super.cancelledAt,
    super.cancelSource,
    super.cancelReason,
    super.hasQuote,
    super.isInquiry,
    super.price,
    super.deliveryCost,
    super.totalCost,
    super.spareBrand,
    super.sparePhotoUrl,
    super.storeLogoUrl,
    super.storeUserId,
    super.storeId,
    super.storePhone,
    super.storeAddress,
    super.storeLat,
    super.storeLng,
    super.verified,
    super.hasDelivery,
    super.distanceKm,
    super.storeRating,
    super.storeReviewCount,
    super.note,
    super.hasConversation,
    super.hasReviewed,
    super.reviewRating,
    super.reviewComment,
    super.vehicleTitle,
    super.subcategoryName,
    super.partType,
    super.requestDetails,
    super.offerMessage,
  });

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    // Helper para parsear campos numéricos que Prisma puede enviar como String o num
    double? parseDouble(dynamic v) => v == null
        ? null
        : (v is num ? v.toDouble() : double.tryParse(v.toString()));
    int? parseInt(dynamic v) => v == null
        ? null
        : (v is int ? v : (v is num ? v.toInt() : int.tryParse(v.toString())));

    return ChatConversationModel(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String?,
      threadId:
          json['threadId'] as String? ?? json['offerId'] as String? ?? 'DIRECT',
      participantName: json['participantName'] as String? ?? 'Usuario',
      participantAvatarUrl: json['participantAvatarUrl'] as String?,
      lastMessage: json['lastMessage'] as String? ?? '',
      unreadCount: parseInt(json['unreadCount']) ?? 0,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      offerId: json['offerId'] as String?,
      offerStatus: json['offerStatus'] as String?,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.tryParse(json['cancelledAt'].toString())
          : null,
      cancelSource: json['cancelSource'] as String?,
      cancelReason: json['cancelReason'] as String?,
      hasQuote: json['hasQuote'] as bool? ?? false,
      isInquiry: json['isInquiry'] as bool? ??
          (json['offerStatus'] as String?) == 'INQUIRY',
      price: parseDouble(json['price']),
      deliveryCost: parseDouble(json['deliveryCost']),
      totalCost: parseDouble(json['totalCost']),
      spareBrand: json['spareBrand'] as String?,
      sparePhotoUrl: json['sparePhotoUrl'] as String?,
      storeUserId: json['storeUserId'] as String?,
      storeId: json['storeId'] as String?,
      storePhone: json['storePhone'] as String?,
      storeAddress: json['storeAddress'] as String?,
      hasDelivery: json['hasDelivery'] as bool? ?? false,
      storeLat: parseDouble(json['storeLat']),
      storeLng: parseDouble(json['storeLng']),
      hasReviewed: json['hasReviewed'] as bool? ?? false,
      reviewRating: parseInt(json['reviewRating']),
      reviewComment: json['reviewComment'] as String?,
      vehicleTitle: json['vehicleTitle'] as String?,
      subcategoryName: json['subcategoryName'] as String?,
      partType: json['partType'] as String?,
      requestDetails: json['requestDetails'] as String?,
      offerMessage: json['offerMessage'] as String?,
      storeRating: parseDouble(json['storeRating']),
      storeReviewCount: parseInt(json['storeRatingCount']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'threadId': threadId,
        'participantName': participantName,
        'participantAvatarUrl': participantAvatarUrl,
        'lastMessage': lastMessage,
        'unreadCount': unreadCount,
        'lastMessageAt': lastMessageAt.toIso8601String(),
        'offerId': offerId,
        'offerStatus': offerStatus,
        'cancelledAt': cancelledAt?.toIso8601String(),
        'cancelSource': cancelSource,
        'cancelReason': cancelReason,
        'hasQuote': hasQuote,
        'isInquiry': isInquiry,
        'price': price,
        'deliveryCost': deliveryCost,
        'totalCost': totalCost,
        'spareBrand': spareBrand,
        'sparePhotoUrl': sparePhotoUrl,
        'storeRating': storeRating,
        'storeRatingCount': storeReviewCount,
      };
}
