import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/notifications_repository.dart';

class GetUnreadNotificationsCountUseCase {
  const GetUnreadNotificationsCountUseCase(this._repository);

  final NotificationsRepository _repository;

  Future<Either<Failure, int>> call() {
    return _repository.getUnreadCount();
  }
}
