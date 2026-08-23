import 'package:equatable/equatable.dart';
import '../../../../core/domain/enums/service_type.dart';

class ChatThread extends Equatable {
  final String id;
  final String title;
  final ServiceType requestType;
  final int unreadCount;
  final int conversationCount;
  final DateTime lastActivityAt;
  final bool isOpen;
  final String? clientName; // Nombre del creador (para vista de tienda)
  final String? clientId;
  final String? fotoUrl;

  // Extra details for the UI
  final String? details;
  final String? partType;
  final int? vehicleYear;
  final String? vehicleType;
  final String? subcategory;
  final DateTime? expiresAt;
  final bool isExpired;
  final int totalOffersCount;
  final String? consumerAvatar;
  final double? distance;

  // Store Offer Status
  final bool hasOffer;
  final String? offerId;
  final String? offerStatus;
  final double? offerPrice;
  final double? deliveryCost;
  final double? totalCost;
  final String? conversationId;
  final String? searchMatchId;
  final String? matchState;
  final DateTime? declinedAt;
  final String? declineReason;
  final bool isInquiry;
  final DateTime? cancelledAt;
  final String? cancelSource;
  final String? cancelReason;

  // Consumer Best Offer Info
  final double? bestOfferPrice;
  final String? bestOfferStoreName;
  final String? bestOfferStatus;

  final String? lastMessage;

  const ChatThread({
    required this.id,
    required this.title,
    required this.requestType,
    required this.unreadCount,
    required this.conversationCount,
    required this.lastActivityAt,
    this.isOpen = true,
    this.clientName,
    this.clientId,
    this.fotoUrl,
    this.details,
    this.partType,
    this.vehicleYear,
    this.vehicleType,
    this.subcategory,
    this.expiresAt,
    this.isExpired = false,
    this.totalOffersCount = 0,
    this.consumerAvatar,
    this.distance,
    this.hasOffer = false,
    this.offerId,
    this.offerStatus,
    this.offerPrice,
    this.deliveryCost,
    this.totalCost,
    this.conversationId,
    this.searchMatchId,
    this.matchState,
    this.declinedAt,
    this.declineReason,
    this.isInquiry = false,
    this.cancelledAt,
    this.cancelSource,
    this.cancelReason,
    this.bestOfferPrice,
    this.bestOfferStoreName,
    this.bestOfferStatus,
    this.lastMessage,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        requestType,
        unreadCount,
        conversationCount,
        lastActivityAt,
        isOpen,
        clientName,
        clientId,
        fotoUrl,
        details,
        partType,
        vehicleYear,
        subcategory,
        expiresAt,
        isExpired,
        totalOffersCount,
        consumerAvatar,
        distance,
        hasOffer,
        offerId,
        offerStatus,
        offerPrice,
        deliveryCost,
        totalCost,
        conversationId,
        searchMatchId,
        matchState,
        declinedAt,
        declineReason,
        isInquiry,
        cancelledAt,
        cancelSource,
        cancelReason,
        bestOfferPrice,
        bestOfferStoreName,
        bestOfferStatus,
        lastMessage,
      ];
}
