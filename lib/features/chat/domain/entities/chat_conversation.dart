import 'package:equatable/equatable.dart';

class ChatConversation extends Equatable {
  final String id;
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
  final bool isFixedPrice;
  final double? price;
  final double? minPrice;
  final double? maxPrice;
  final String? spareBrand;
  final String? sparePhotoUrl;

  // Store trust signals (offer card, estilo marketplace)
  final String? storeLogoUrl;
  final String? storeUserId;
  final String? storeId;
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
    required this.threadId,
    required this.participantName,
    this.participantAvatarUrl,
    required this.lastMessage,
    required this.unreadCount,
    required this.lastMessageAt,
    this.offerId,
    this.offerStatus,
    this.hasQuote = false,
    this.isFixedPrice = true,
    this.price,
    this.minPrice,
    this.maxPrice,
    this.spareBrand,
    this.sparePhotoUrl,
    this.storeLogoUrl,
    this.storeUserId,
    this.storeId,
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
    if (!hasQuote) return 'Sin cotizar';
    if (isFixedPrice) {
      return '\$${price?.toStringAsFixed(0)}';
    } else {
      return '\$${minPrice?.toStringAsFixed(0)} - \$${maxPrice?.toStringAsFixed(0)}';
    }
  }

  /// Distancia legible para chips ("1.2 km"). Null si no hay dato válido.
  String? get formattedDistance {
    final d = distanceKm;
    if (d == null || d <= 0) return null;
    return '${d.toStringAsFixed(1)} km';
  }

  @override
  List<Object?> get props => [
        id,
        threadId,
        participantName,
        participantAvatarUrl,
        lastMessage,
        unreadCount,
        lastMessageAt,
        offerId,
        offerStatus,
        hasQuote,
        isFixedPrice,
        price,
        minPrice,
        maxPrice,
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
