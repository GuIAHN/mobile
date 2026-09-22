import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

class MarkAsReadUseCase {
  final ChatRepository repository;

  MarkAsReadUseCase(this.repository);

  Future<Either<Failure, void>> call(String conversationId) async {
    return repository.markAsRead(conversationId);
  }
}
