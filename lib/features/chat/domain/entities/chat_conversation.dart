import 'package:equatable/equatable.dart';

class ChatConversation extends Equatable {
  final String id;

  /// Identificador del chat en tiempo real.
  ///
  /// En la bandeja general coincide con [id]. En el detalle de una solicitud,
  /// [id] identifica la oferta y este campo permite asociar `message.new` con
  /// el card correcto sin volver a consultar toda la pantalla.
  final String? conversationId;
  final String threadId;
  final String participantName;
  final String? participantAvatarUrl;
  final String lastMessage;
  final int unreadCount;
  final DateTime lastMessageAt;

  final String? offerId;
  final String? offerStatus;

  // Pricing Quote Fields
  final bool hasQuote;
  final bool isInquiry;
  final double? price;
  final String? spareBrand;
  final String? sparePhotoUrl;

  // Store trust & contact signals (offer card, estilo marketplace)
  final String? storeLogoUrl;
  final String? storeUserId;
  final String? storeId;
  final String? storePhone;
  final String? storeAddress;
  final double? storeLat;
  final double? storeLng;
  final bool verified;
  final bool hasDelivery;
  final double? distanceKm;
  final double? storeRating;
  final int storeReviewCount;
  final String? note;
  final bool hasConversation;
  final bool hasReviewed;
  final int? reviewRating;
  final String? reviewComment;

  // Contextual Request & Offer Details
  final String? vehicleTitle;
  final String? subcategoryName;
  final String? partType;
  final String? requestDetails;
  final String? offerMessage;

  const ChatConversation({
    required this.id,
    this.conversationId,
    required this.threadId,
    required this.participantName,
    this.participantAvatarUrl,
    required this.lastMessage,
    required this.unreadCount,
    required this.lastMessageAt,
    this.offerId,
    this.offerStatus,
    this.hasQuote = false,
    this.isInquiry = false,
    this.price,
    this.spareBrand,
    this.sparePhotoUrl,
    this.storeLogoUrl,
    this.storeUserId,
    this.storeId,
    this.storePhone,
    this.storeAddress,
    this.storeLat,
    this.storeLng,
    this.verified = false,
    this.hasDelivery = false,
    this.distanceKm,
    this.storeRating,
    this.storeReviewCount = 0,
    this.note,
    this.hasConversation = false,
    this.hasReviewed = false,
    this.reviewRating,
    this.reviewComment,
    this.vehicleTitle,
    this.subcategoryName,
    this.partType,
    this.requestDetails,
    this.offerMessage,
  });

  String get formattedPrice {
    if (!hasQuote || price == null) return 'Sin cotizar';
    return '\$${price!.toStringAsFixed(0)}';
  }

  /// Distancia legible para chips ("1.2 km"). Null si no hay dato válido.
  String? get formattedDistance {
    final d = distanceKm;
    if (d == null || d <= 0) return null;
    return '${d.toStringAsFixed(1)} km';
  }

  String get realtimeConversationId => conversationId ?? id;

  ChatConversation withRealtimePreview({
    required String lastMessage,
    required int unreadCount,
    required DateTime lastMessageAt,
  }) {
    return ChatConversation(
      id: id,
      conversationId: conversationId,
      threadId: threadId,
      participantName: participantName,
      participantAvatarUrl: participantAvatarUrl,
      lastMessage: lastMessage,
      unreadCount: unreadCount,
      lastMessageAt: lastMessageAt,
      offerId: offerId,
      offerStatus: offerStatus,
      hasQuote: hasQuote,
      isInquiry: isInquiry,
      price: price,
      spareBrand: spareBrand,
      sparePhotoUrl: sparePhotoUrl,
      storeLogoUrl: storeLogoUrl,
      storeUserId: storeUserId,
      storeId: storeId,
      storePhone: storePhone,
      storeAddress: storeAddress,
      storeLat: storeLat,
      storeLng: storeLng,
      verified: verified,
      hasDelivery: hasDelivery,
      distanceKm: distanceKm,
      storeRating: storeRating,
      storeReviewCount: storeReviewCount,
      note: note,
      hasConversation: hasConversation,
      hasReviewed: hasReviewed,
      reviewRating: reviewRating,
      reviewComment: reviewComment,
      vehicleTitle: vehicleTitle,
      subcategoryName: subcategoryName,
      partType: partType,
      requestDetails: requestDetails,
      offerMessage: offerMessage,
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        threadId,
        participantName,
        participantAvatarUrl,
        lastMessage,
        unreadCount,
        lastMessageAt,
        offerId,
        offerStatus,
        hasQuote,
        isInquiry,
        price,
        spareBrand,
        sparePhotoUrl,
        storeLogoUrl,
        verified,
        hasDelivery,
        distanceKm,
        storeRating,
        storeReviewCount,
        note,
        hasConversation,
      ];
}
