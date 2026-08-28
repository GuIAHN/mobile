import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

class CancelSaleByStoreUseCase {
  const CancelSaleByStoreUseCase(this.repository);

  final ChatRepository repository;

  Future<Either<Failure, void>> call(
    String offerId, {
    required String reasonCode,
    String? note,
  }) {
    return repository.cancelSaleByStore(
      offerId,
      reasonCode: reasonCode,
      note: note,
    );
  }
}
