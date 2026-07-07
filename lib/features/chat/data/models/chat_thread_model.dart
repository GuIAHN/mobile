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
  });

  factory ChatThreadModel.fromJson(Map<String, dynamic> json) {
    return ChatThreadModel(
      id: json['id'] as String,
      title: json['title'] as String,
      requestType: ServiceType.values.firstWhere(
        (e) => e.name == json['requestType'],
        orElse: () => ServiceType.spareParts,
      ),
      unreadCount: json['unreadCount'] as int? ?? 0,
      conversationCount: json['conversationCount'] as int? ?? 0,
      lastActivityAt: DateTime.parse(json['lastActivityAt'] as String),
      isOpen: json['isOpen'] as bool? ?? true,
      clientName: json['clientName'] as String?,
      clientId: json['clientId'] as String?,
      fotoUrl: json['fotoUrl'] as String? ?? json['foto_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'requestType': requestType.name,
        'unreadCount': unreadCount,
        'conversationCount': conversationCount,
        'lastActivityAt': lastActivityAt.toIso8601String(),
        'isOpen': isOpen,
        'clientName': clientName,
        'clientId': clientId,
        'fotoUrl': fotoUrl,
      };
}
