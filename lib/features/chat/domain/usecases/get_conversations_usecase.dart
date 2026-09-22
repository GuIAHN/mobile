import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/chat_conversation.dart';
import '../repositories/chat_repository.dart';

class GetConversationsUseCase {
  final ChatRepository repository;
  GetConversationsUseCase(this.repository);

  Future<Either<Failure, List<ChatConversation>>> call(String threadId) =>
      repository.getConversations(threadId);
}
