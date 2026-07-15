import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/chat_conversation.dart';
import '../repositories/chat_repository.dart';

class CreateQuoteUseCase {
  final ChatRepository repository;
  CreateQuoteUseCase(this.repository);

  Future<Either<Failure, ChatConversation>> call({
    required String threadId,
    required bool isFixedPrice,
    double? price,
    double? minPrice,
    double? maxPrice,
    String? brand,
    String? photoPath,
  }) =>
      repository.createQuote(
        threadId: threadId,
        isFixedPrice: isFixedPrice,
        price: price,
        minPrice: minPrice,
        maxPrice: maxPrice,
        brand: brand,
        photoPath: photoPath,
      );
}
