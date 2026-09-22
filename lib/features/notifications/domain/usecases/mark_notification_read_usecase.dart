import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/notifications_repository.dart';

class MarkNotificationReadUseCase {
  const MarkNotificationReadUseCase(this._repository);

  final NotificationsRepository _repository;

  Future<Either<Failure, void>> call(String id) {
    return _repository.markRead(id);
  }
}
