import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

class DeclineMatchUseCase {
  final ChatRepository repository;

  DeclineMatchUseCase(this.repository);

  Future<Either<Failure, void>> call(
    String searchMatchId,
    String reason,
  ) {
    return repository.declineMatch(searchMatchId, reason);
  }
}
