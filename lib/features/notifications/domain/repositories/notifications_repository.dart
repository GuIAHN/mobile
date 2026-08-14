import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_notification.dart';

abstract class NotificationsRepository {
  Future<Either<Failure, List<UserNotification>>> getUnread({
    int page = 1,
    int limit = 20,
  });

  Future<Either<Failure, void>> markRead(String id);

  Future<Either<Failure, void>> markAllRead();

  Future<Either<Failure, int>> getUnreadCount();
}
