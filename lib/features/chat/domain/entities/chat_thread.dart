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
  final String? subcategoryId;
  final bool subcategoryIsCatchAll;
  final String? categoryId;
  final String? categoryName;
  final DateTime? expiresAt;
  final bool isExpired;
  final int totalOffersCount;
  final int quotesCount;
  final int questionsCount;
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
  final String? cancelReasonCode;

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
    this.subcategoryId,
    this.subcategoryIsCatchAll = false,
    this.categoryId,
    this.categoryName,
    this.expiresAt,
    this.isExpired = false,
    this.totalOffersCount = 0,
    this.quotesCount = 0,
    this.questionsCount = 0,
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
    this.cancelReasonCode,
    this.bestOfferPrice,
    this.bestOfferStoreName,
    this.bestOfferStatus,
    this.lastMessage,
  });

  /// Una consulta ya abrió una conversación, pero todavía no constituye una
  /// cotización. Se toleran las tres señales que el API ha usado para este
  /// estado para evitar que la UI la presente como una oferta enviada.
  bool get isInquiryState =>
      isInquiry ||
      matchState?.toUpperCase() == 'INQUIRING' ||
      offerStatus?.toUpperCase() == 'INQUIRY';

  /// `hasOffer` también es true para consultas porque el backend conserva una
  /// oferta INQUIRY como soporte del chat. Solo las no-consultas son una
  /// cotización formal desde la perspectiva de la tienda.
  bool get hasFormalQuote => hasOffer && !isInquiryState;

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
        vehicleType,
        subcategory,
        subcategoryId,
        subcategoryIsCatchAll,
        categoryId,
        categoryName,
        expiresAt,
        isExpired,
        totalOffersCount,
        quotesCount,
        questionsCount,
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
        cancelReasonCode,
        bestOfferPrice,
        bestOfferStoreName,
        bestOfferStatus,
        lastMessage,
      ];
}
