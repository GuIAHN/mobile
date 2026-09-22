import '../../domain/entities/chat_conversation.dart';

class ChatConversationModel extends ChatConversation {
  const ChatConversationModel({
    required super.id,
    super.conversationId,
    required super.threadId,
    required super.participantName,
    super.participantAvatarUrl,
    required super.lastMessage,
    super.lastMessageIsFromMe,
    required super.unreadCount,
    required super.lastMessageAt,
    super.offerId,
    super.offerStatus,
    super.searchMatchId,
    super.declinedAt,
    super.declineReason,
    super.cancelledAt,
    super.cancelSource,
    super.cancelReason,
    super.cancelReasonCode,
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
    super.subcategoryIsCatchAll,
    super.categoryId,
    super.categoryName,
    super.partType,
    super.requestDetails,
    super.offerMessage,
  });

  factory ChatConversationModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    // Helper para parsear campos numéricos que Prisma puede enviar como String o num
    double? parseDouble(dynamic v) => v == null
        ? null
        : (v is num ? v.toDouble() : double.tryParse(v.toString()));
    int? parseInt(dynamic v) => v == null
        ? null
        : (v is int ? v : (v is num ? v.toInt() : int.tryParse(v.toString())));

    final lastMessageSenderId =
        (json['lastMessageSenderId'] ?? json['lastMessageSender']?['id'])
            ?.toString();
    final explicitAuthorship = json['lastMessageIsFromMe'];
    final category = json['category'];
    final categoryMap =
        category is Map ? Map<String, dynamic>.from(category) : null;

    return ChatConversationModel(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String?,
      threadId:
          json['threadId'] as String? ?? json['offerId'] as String? ?? 'DIRECT',
      participantName: json['participantName'] as String? ?? 'Usuario',
      participantAvatarUrl: json['participantAvatarUrl'] as String?,
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageIsFromMe: explicitAuthorship is bool
          ? explicitAuthorship
          : currentUserId != null &&
                  currentUserId.isNotEmpty &&
                  lastMessageSenderId != null
              ? lastMessageSenderId == currentUserId
              : null,
      unreadCount: parseInt(json['unreadCount']) ?? 0,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      offerId: json['offerId'] as String?,
      offerStatus: json['offerStatus'] as String?,
      searchMatchId: json['searchMatchId'] as String?,
      declinedAt: json['declinedAt'] != null
          ? DateTime.tryParse(json['declinedAt'].toString())
          : null,
      declineReason: json['declineReason'] as String?,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.tryParse(json['cancelledAt'].toString())
          : null,
      cancelSource: json['cancelSource'] as String?,
      cancelReason: json['cancelReason'] as String?,
      cancelReasonCode: json['cancelReasonCode'] as String?,
      hasQuote: json['hasQuote'] as bool? ?? false,
      isInquiry: json['isInquiry'] as bool? ??
          (json['offerStatus'] as String?) == 'INQUIRY',
      price: parseDouble(json['price']),
      deliveryCost: parseDouble(json['deliveryCost']),
      totalCost: parseDouble(json['totalCost']),
      spareBrand: json['spareBrand'] as String?,
      sparePhotoUrl: json['sparePhotoUrl'] as String?,
      storeLogoUrl: json['storeLogoUrl'] as String?,
      storeUserId: json['storeUserId'] as String?,
      storeId: json['storeId'] as String?,
      storePhone: json['storePhone'] as String?,
      storeAddress: json['storeAddress'] as String?,
      hasDelivery: json['hasDelivery'] as bool? ?? false,
      verified: json['verified'] as bool? ?? false,
      storeLat: parseDouble(json['storeLat']),
      storeLng: parseDouble(json['storeLng']),
      distanceKm: parseDouble(json['distanceKm']),
      note: json['note'] as String?,
      hasConversation: json['hasConversation'] as bool? ?? false,
      hasReviewed: json['hasReviewed'] as bool? ?? false,
      reviewRating: parseInt(json['reviewRating']),
      reviewComment: json['reviewComment'] as String?,
      vehicleTitle: json['vehicleTitle'] as String?,
      subcategoryName: json['subcategoryName'] as String?,
      subcategoryIsCatchAll: json['subcategoryIsCatchAll'] as bool? ?? false,
      categoryId: categoryMap?['id']?.toString(),
      categoryName: categoryMap?['name']?.toString(),
      partType: json['partType'] as String?,
      requestDetails: json['requestDetails'] as String?,
      offerMessage: json['offerMessage'] as String?,
      storeRating: parseDouble(json['storeRating']),
      storeReviewCount: parseInt(json['storeRatingCount']) ?? 0,
    );
  }
}
