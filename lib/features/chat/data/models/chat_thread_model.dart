import '../../domain/entities/chat_thread.dart';
import '../../../../core/domain/enums/service_type.dart';

class ChatThreadModel extends ChatThread {
  const ChatThreadModel({
    required super.id,
    required super.title,
    required super.requestType,
    required super.unreadCount,
    required super.conversationCount,
    required super.lastActivityAt,
    super.isOpen,
    super.clientName,
    super.clientId,
    super.fotoUrl,
    super.details,
    super.partType,
    super.vehicleYear,
    super.vehicleType,
    super.subcategory,
    super.expiresAt,
    super.isExpired,
    super.totalOffersCount,
    super.consumerAvatar,
    super.distance,
    super.hasOffer,
    super.offerId,
    super.offerStatus,
    super.offerPrice,
    super.deliveryCost,
    super.totalCost,
    super.conversationId,
    super.searchMatchId,
    super.matchState,
    super.declinedAt,
    super.declineReason,
    super.isInquiry,
    super.cancelledAt,
    super.cancelSource,
    super.cancelReason,
    super.cancelReasonCode,
    super.bestOfferPrice,
    super.bestOfferStoreName,
    super.bestOfferStatus,
    super.lastMessage,
  });

  factory ChatThreadModel.fromJson(Map<String, dynamic> json) {
    final vehicle = json['vehicle'] as Map<String, dynamic>?;
    final model = vehicle?['model'] as Map<String, dynamic>?;
    final parsedVehicleType =
        model?['vehicleType'] as String? ?? json['vehicleType'] as String?;

    return ChatThreadModel(
      id: json['id'] as String,
      title: json['title'] as String,
      requestType: ServiceType.values.firstWhere(
        (e) => e.name == json['requestType'],
        orElse: () => ServiceType.spareParts,
      ),
      unreadCount: json['unreadCount'] as int? ?? 0,
      conversationCount: json['conversationCount'] as int? ?? 0,
      lastActivityAt: DateTime.parse(
          json['lastActivityAt'] as String? ?? json['createdAt'] as String),
      isOpen: json['isOpen'] as bool? ??
          (json['requestStatus'] == 'OPEN' || json['status'] == 'OPEN'),
      clientName:
          json['clientName'] as String? ?? json['consumerName'] as String?,
      clientId: json['clientId'] as String?,
      fotoUrl: json['fotoUrl'] as String? ?? json['photoUrl'] as String?,
      details: json['details'] as String?,
      partType: json['partType'] as String?,
      vehicleYear: json['vehicleYear'] as int? ?? vehicle?['year'] as int?,
      vehicleType: parsedVehicleType,
      subcategory: json['subcategory'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
      isExpired: json['isExpired'] as bool? ?? false,
      totalOffersCount: json['totalOffersCount'] as int? ??
          json['conversationCount'] as int? ??
          0,
      consumerAvatar: json['consumerAvatar'] as String?,
      distance: json['distance'] != null
          ? double.tryParse(json['distance'].toString())
          : json['distancia'] != null
              ? double.tryParse(json['distancia'].toString())
              : null,
      hasOffer: json['hasOffer'] as bool? ?? false,
      offerId: json['offerId'] as String?,
      offerStatus: json['offerStatus'] as String?,
      offerPrice: json['offerPrice'] != null
          ? double.tryParse(json['offerPrice'].toString())
          : null,
      deliveryCost: json['deliveryCost'] != null
          ? double.tryParse(json['deliveryCost'].toString())
          : null,
      totalCost: json['totalCost'] != null
          ? double.tryParse(json['totalCost'].toString())
          : null,
      conversationId: json['conversationId'] as String?,
      searchMatchId: json['searchMatchId'] as String?,
      matchState: json['matchState'] as String?,
      declinedAt: json['declinedAt'] != null
          ? DateTime.tryParse(json['declinedAt'].toString())
          : null,
      declineReason: json['declineReason'] as String?,
      isInquiry: json['isInquiry'] as bool? ?? false,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.tryParse(json['cancelledAt'].toString())
          : null,
      cancelSource: json['cancelSource'] as String?,
      cancelReason: json['cancelReason'] as String?,
      cancelReasonCode: json['cancelReasonCode'] as String?,
      bestOfferPrice: json['bestOfferPrice'] != null
          ? double.tryParse(json['bestOfferPrice'].toString())
          : null,
      bestOfferStoreName: json['bestOfferStoreName'] as String?,
      bestOfferStatus: json['bestOfferStatus'] as String?,
      lastMessage: json['lastMessage'] as String?,
    );
  }
}
