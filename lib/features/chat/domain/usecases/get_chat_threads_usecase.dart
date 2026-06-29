import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/chat_thread.dart';
import '../repositories/chat_repository.dart';

class GetChatThreadsUseCase {
  final ChatRepository repository;
  GetChatThreadsUseCase(this.repository);

  Future<Either<Failure, List<ChatThread>>> call() => repository.getChatThreads();
}
