import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/chat_threads_result.dart';
import '../entities/chat_conversation.dart';
import '../entities/chat_message.dart';
import '../../../../core/domain/enums/user_role.dart';

abstract class ChatRepository {
  Future<Either<Failure, ChatThreadsResult>> getChatThreads({
    UserRole? role,
    String? statusFilter,
    int page = 1,
    int pageSize = 20,
  });

  Future<Either<Failure, List<ChatConversation>>> getConversations(
      String threadId);

  Future<Either<Failure, List<ChatMessage>>> getMessages(String conversationId);

  Future<Either<Failure, ChatMessage?>> getLatestMessage(String conversationId);

  Future<Either<Failure, ChatConversation>> createQuote({
    required String threadId,
    String? searchMatchId,
    double? price,
    double? deliveryCost,
    String? brand,
    String? photoPath,
  });

  Future<Either<Failure, void>> quoteOffer({
    required String offerId,
    required double price,
    required bool updateDeliveryCost,
    double? deliveryCost,
    String? brand,
    String? photoPath,
  });

  Future<Either<Failure, String>> startChatFromOffer(String offerId);

  Future<Either<Failure, List<ChatConversation>>> getMyConversations();

  Future<Either<Failure, ChatConversation>> getConversationDetails(
      String conversationId);

  Future<Either<Failure, void>> buyOffer(String offerId);

  Future<Either<Failure, void>> deliverOffer(String offerId);

  Future<Either<Failure, void>> cancelOffer(
    String offerId, {
    String? reason,
  });

  Future<Either<Failure, void>> cancelSaleByStore(
    String offerId, {
    required String reasonCode,
    String? note,
  });

  Future<Either<Failure, void>> declineMatch(
    String searchMatchId,
    String reason,
  );

  Future<Either<Failure, void>> undoDecline(String searchMatchId);

  Future<Either<Failure, void>> markAsRead(String conversationId);
}
