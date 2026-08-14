import 'package:dartz/dartz.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._remoteDatasource);

  final NotificationsRemoteDatasource _remoteDatasource;

  @override
  Future<Either<Failure, List<UserNotification>>> getUnread({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final notifications = await _remoteDatasource.getUnreadNotifications(
        page: page,
        limit: limit,
      );
      return Right(notifications);
    } catch (error) {
      return Left(ErrorMapper.map(error));
    }
  }

  @override
  Future<Either<Failure, void>> markRead(String id) async {
    try {
      await _remoteDatasource.markRead(id);
      return const Right(null);
    } catch (error) {
      return Left(ErrorMapper.map(error));
    }
  }

  @override
  Future<Either<Failure, void>> markAllRead() async {
    try {
      await _remoteDatasource.markAllRead();
      return const Right(null);
    } catch (error) {
      return Left(ErrorMapper.map(error));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    try {
      return Right(await _remoteDatasource.getUnreadCount());
    } catch (error) {
      return Left(ErrorMapper.map(error));
    }
  }
}
