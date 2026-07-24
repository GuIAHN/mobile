import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/chat_thread.dart';
import '../entities/chat_threads_result.dart';
import '../repositories/chat_repository.dart';

class GetChatThreadsUseCase {
  final ChatRepository repository;
  GetChatThreadsUseCase(this.repository);

  Future<Either<Failure, ChatThreadsResult>> call({
    String? statusFilter,
    int page = 1,
    int pageSize = 20,
  }) =>
      repository.getChatThreads(
        statusFilter: statusFilter,
        page: page,
        pageSize: pageSize,
      );
}
