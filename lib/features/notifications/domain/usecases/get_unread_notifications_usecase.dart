import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_notification.dart';
import '../repositories/notifications_repository.dart';

class GetUnreadNotificationsUseCase {
  const GetUnreadNotificationsUseCase(this._repository);

  final NotificationsRepository _repository;

  Future<Either<Failure, List<UserNotification>>> call({
    int page = 1,
    int limit = 20,
  }) {
    return _repository.getUnread(page: page, limit: limit);
  }
}
