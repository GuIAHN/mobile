import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/chat_thread.dart';
import '../entities/chat_threads_result.dart';
import '../entities/chat_conversation.dart';
import '../entities/chat_message.dart';

abstract class ChatRepository {
  Future<Either<Failure, ChatThreadsResult>> getChatThreads({
    String? statusFilter,
    int page = 1,
    int pageSize = 20,
  });
  
  Future<Either<Failure, List<ChatConversation>>> getConversations(String threadId);
  
  Future<Either<Failure, List<ChatMessage>>> getMessages(String conversationId);
  
  Future<Either<Failure, ChatMessage>> sendMessage(String conversationId, String content);
  
  Future<Either<Failure, ChatConversation>> createQuote({
    required String threadId,
    required bool isFixedPrice,
    double? price,
    double? minPrice,
    double? maxPrice,
    String? brand,
    String? photoPath,
  });

  Future<Either<Failure, String>> startChatFromOffer(String offerId);
  
  Future<Either<Failure, List<ChatConversation>>> getMyConversations();
  
  Future<Either<Failure, ChatConversation>> getConversationDetails(String conversationId);

  Future<Either<Failure, void>> buyOffer(String offerId);
  
  Future<Either<Failure, void>> deliverOffer(String offerId);
  
  Future<Either<Failure, void>> markAsRead(String conversationId);
}
