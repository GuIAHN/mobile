import '../../domain/entities/chat_conversation.dart';

class ChatConversationModel extends ChatConversation {
  const ChatConversationModel({
    required super.id,
    required super.threadId,
    required super.participantName,
    super.participantAvatarUrl,
    required super.lastMessage,
    required super.unreadCount,
    required super.lastMessageAt,
    super.hasQuote,
    super.isFixedPrice,
    super.price,
    super.minPrice,
    super.maxPrice,
    super.spareBrand,
    super.sparePhotoUrl,
    super.storeLogoUrl,
    super.verified,
    super.hasDelivery,
    super.distanceKm,
    super.note,
    super.hasConversation,
  });

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    return ChatConversationModel(
      id: json['id'] as String,
      threadId: json['threadId'] as String,
      participantName: json['participantName'] as String,
      participantAvatarUrl: json['participantAvatarUrl'] as String?,
      lastMessage: json['lastMessage'] as String? ?? '',
      unreadCount: json['unreadCount'] as int? ?? 0,
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      hasQuote: json['hasQuote'] as bool? ?? false,
      isFixedPrice: json['isFixedPrice'] as bool? ?? true,
      price: (json['price'] as num?)?.toDouble(),
      minPrice: (json['minPrice'] as num?)?.toDouble(),
      maxPrice: (json['maxPrice'] as num?)?.toDouble(),
      spareBrand: json['spareBrand'] as String?,
      sparePhotoUrl: json['sparePhotoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'threadId': threadId,
        'participantName': participantName,
        'participantAvatarUrl': participantAvatarUrl,
        'lastMessage': lastMessage,
        'unreadCount': unreadCount,
        'lastMessageAt': lastMessageAt.toIso8601String(),
        'hasQuote': hasQuote,
        'isFixedPrice': isFixedPrice,
        'price': price,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'spareBrand': spareBrand,
        'sparePhotoUrl': sparePhotoUrl,
      };
}
