import '../../domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.senderName,
    required super.isFromMe,
    required super.content,
    super.type,
    required super.createdAt,
    super.isRead,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json, String currentUserId) {
    return ChatMessageModel(
      id: json['_id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] ?? 'Usuario',
      isFromMe: json['senderId'] == currentUserId,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        'isFromMe': isFromMe,
        'content': content,
        'type': type.name,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
      };
}
