import 'package:dartz/dartz.dart';

import '../../../../core/domain/enums/user_role.dart';
import '../../../../core/error/failures.dart';
import '../entities/chat_thread.dart';
import '../repositories/chat_repository.dart';

class GetRequestDetailUseCase {
  const GetRequestDetailUseCase(this.repository);

  final ChatRepository repository;

  Future<Either<Failure, ChatThread>> call(
    String requestId, {
    UserRole? role,
  }) =>
      repository.getRequestDetail(requestId, role: role);
}
