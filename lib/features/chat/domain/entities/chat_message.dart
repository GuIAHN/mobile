import 'package:equatable/equatable.dart';

enum MessageType {
  text,
  image,
  system,
}

class ChatMessage extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final bool isFromMe;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.isFromMe,
    required this.content,
    this.type = MessageType.text,
    required this.createdAt,
    this.isRead = false,
  });

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        senderName,
        isFromMe,
        content,
        type,
        createdAt,
        isRead,
      ];
}
