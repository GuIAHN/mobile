import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/error/failures.dart';
import 'package:guiautomotriz_mobile/core/services/socket_service.dart';
import 'package:guiautomotriz_mobile/features/notifications/domain/entities/user_notification.dart';
import 'package:guiautomotriz_mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:guiautomotriz_mobile/features/notifications/domain/usecases/get_unread_notifications_count_usecase.dart';
import 'package:guiautomotriz_mobile/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockSocketService extends Mock implements SocketService {}

class _CountingNotificationsRepository implements NotificationsRepository {
  int countCalls = 0;

  @override
  Future<Either<Failure, int>> getUnreadCount() async => Right(++countCalls);

  @override
  Future<Either<Failure, List<UserNotification>>> getUnread({
    int page = 1,
    int limit = 20,
  }) async =>
      const Right([]);

  @override
  Future<Either<Failure, void>> markAllRead() async => const Right(null);

  @override
  Future<Either<Failure, void>> markRead(String id) async => const Right(null);
}

void main() {
  test('does not refetch unread count on the initial socket connection',
      () async {
    final socket = _MockSocketService();
    final notifications = StreamController<Map<String, dynamic>>.broadcast();
    final reconnects = StreamController<void>.broadcast();
    addTearDown(notifications.close);
    addTearDown(reconnects.close);
    when(() => socket.onNotification).thenAnswer((_) => notifications.stream);
    when(() => socket.onReconnect).thenAnswer((_) => reconnects.stream);

    final repository = _CountingNotificationsRepository();
    final container = ProviderContainer(
      overrides: [
        socketServiceProvider.overrideWithValue(socket),
        getUnreadNotificationsCountUseCaseProvider.overrideWithValue(
          GetUnreadNotificationsCountUseCase(repository),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      unreadNotificationsCountProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    expect(await container.read(unreadNotificationsCountProvider.future), 1);
    verifyNever(() => socket.onConnected);
    expect(repository.countCalls, 1);

    reconnects.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 600));

    expect(await container.read(unreadNotificationsCountProvider.future), 2);
    expect(repository.countCalls, 2);
  });
}
