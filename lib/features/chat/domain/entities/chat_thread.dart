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
      ];
}
