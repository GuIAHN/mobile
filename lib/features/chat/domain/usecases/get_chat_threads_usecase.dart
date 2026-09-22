import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/chat_threads_result.dart';
import '../repositories/chat_repository.dart';
import '../../../../core/domain/enums/user_role.dart';

class GetChatThreadsUseCase {
  final ChatRepository repository;
  GetChatThreadsUseCase(this.repository);

  Future<Either<Failure, ChatThreadsResult>> call({
    UserRole? role,
    String? statusFilter,
    int page = 1,
    int pageSize = 20,
  }) =>
      repository.getChatThreads(
        role: role,
        statusFilter: statusFilter,
        page: page,
        pageSize: pageSize,
      );
}
