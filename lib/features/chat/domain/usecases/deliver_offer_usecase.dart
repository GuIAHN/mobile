import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

class DeliverOfferUseCase {
  final ChatRepository repository;

  DeliverOfferUseCase(this.repository);

  Future<Either<Failure, void>> call(String offerId) {
    return repository.deliverOffer(offerId);
  }
}
