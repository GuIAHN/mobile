import 'package:equatable/equatable.dart';

class ChatConversation extends Equatable {
  final String id;
  final String threadId;
  final String participantName;
  final String? participantAvatarUrl;
  final String lastMessage;
  final int unreadCount;
  final DateTime lastMessageAt;
  
  // Pricing Quote Fields
  final bool hasQuote;
  final bool isFixedPrice;
  final double? price;
  final double? minPrice;
  final double? maxPrice;
  final String? spareBrand;
  final String? sparePhotoUrl;

  const ChatConversation({
    required this.id,
    required this.threadId,
    required this.participantName,
    this.participantAvatarUrl,
    required this.lastMessage,
    required this.unreadCount,
    required this.lastMessageAt,
    this.hasQuote = false,
    this.isFixedPrice = true,
    this.price,
    this.minPrice,
    this.maxPrice,
    this.spareBrand,
    this.sparePhotoUrl,
  });

  String get formattedPrice {
    if (!hasQuote) return 'Sin cotizar';
    if (isFixedPrice) {
      return '\$${price?.toStringAsFixed(0)}';
    } else {
      return '\$${minPrice?.toStringAsFixed(0)} - \$${maxPrice?.toStringAsFixed(0)}';
    }
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
        hasQuote,
        isFixedPrice,
        price,
        minPrice,
        maxPrice,
        spareBrand,
        sparePhotoUrl,
      ];
}
