import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

class CancelOfferUseCase {
  final ChatRepository repository;

  CancelOfferUseCase(this.repository);

  Future<Either<Failure, void>> call(
    String offerId, {
    String? reason,
  }) {
    return repository.cancelOffer(offerId, reason: reason);
  }
}
