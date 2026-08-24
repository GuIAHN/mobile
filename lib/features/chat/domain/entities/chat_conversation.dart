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
  final String? searchMatchId;
  final DateTime? declinedAt;
  final String? declineReason;
  final DateTime? cancelledAt;
  final String? cancelSource;
  final String? cancelReason;

  // Pricing Quote Fields
  final bool hasQuote;
  final bool isInquiry;
  final double? price;
  final double? deliveryCost;
  final double? totalCost;
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
    this.searchMatchId,
    this.declinedAt,
    this.declineReason,
    this.cancelledAt,
    this.cancelSource,
    this.cancelReason,
    this.hasQuote = false,
    this.isInquiry = false,
    this.price,
    this.deliveryCost,
    this.totalCost,
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

  String get formattedDeliveryCost {
    if (deliveryCost == null) return 'Retiro en tienda';
    if (deliveryCost == 0) return 'Delivery gratis';
    return '\$${deliveryCost!.toStringAsFixed(0)}';
  }

  String get formattedTotalCost {
    final total = totalCost;
    if (total == null) return formattedPrice;
    return '\$${total.toStringAsFixed(0)}';
  }

  /// Distancia legible para chips ("1.2 km"). Null si no hay dato válido.
  String? get formattedDistance {
    final d = distanceKm;
    if (d == null || d <= 0) return null;
    return '${d.toStringAsFixed(1)} km';
  }

  String get realtimeConversationId => conversationId ?? id;

  /// Una consulta sin precio abre un chat, pero todavía no es una cotización.
  bool get hasFormalQuote => !isInquiry && price != null;

  /// La identidad real de la tienda solo se revela después de registrar una
  /// compra. CANCELLED conserva la identidad porque ese estado ocurre después
  /// de BOUGHT y volver a ocultarla rompería el historial de la conversación.
  bool get revealsStoreIdentity =>
      offerStatus == 'BOUGHT' ||
      offerStatus == 'DELIVERED' ||
      offerStatus == 'CANCELLED';

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
      searchMatchId: searchMatchId,
      declinedAt: declinedAt,
      declineReason: declineReason,
      cancelledAt: cancelledAt,
      cancelSource: cancelSource,
      cancelReason: cancelReason,
      hasQuote: hasQuote,
      isInquiry: isInquiry,
      price: price,
      deliveryCost: deliveryCost,
      totalCost: totalCost,
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
        searchMatchId,
        declinedAt,
        declineReason,
        cancelledAt,
        cancelSource,
        cancelReason,
        hasQuote,
        isInquiry,
        price,
        deliveryCost,
        totalCost,
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
