import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

class QuoteOfferUseCase {
  final ChatRepository repository;
  QuoteOfferUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String offerId,
    double? price,
    double? unitPrice,
    required bool updateDeliveryCost,
    double? deliveryCost,
    String? brand,
    String? photoPath,
  }) =>
      repository.quoteOffer(
        offerId: offerId,
        price: price,
        unitPrice: unitPrice,
        updateDeliveryCost: updateDeliveryCost,
        deliveryCost: deliveryCost,
        brand: brand,
        photoPath: photoPath,
      );
}
