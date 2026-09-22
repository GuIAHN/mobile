import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

class BuyOfferUseCase {
  final ChatRepository repository;

  BuyOfferUseCase(this.repository);

  Future<Either<Failure, void>> call(String offerId) {
    return repository.buyOffer(offerId);
  }
}
