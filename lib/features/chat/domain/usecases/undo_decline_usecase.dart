import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

class UndoDeclineUseCase {
  final ChatRepository repository;

  UndoDeclineUseCase(this.repository);

  Future<Either<Failure, void>> call(String searchMatchId) {
    return repository.undoDecline(searchMatchId);
  }
}
