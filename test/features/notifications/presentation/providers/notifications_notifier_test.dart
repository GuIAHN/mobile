import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/error/failures.dart';
import 'package:guiautomotriz_mobile/features/notifications/domain/entities/user_notification.dart';
import 'package:guiautomotriz_mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:guiautomotriz_mobile/features/notifications/domain/usecases/get_unread_notifications_usecase.dart';
import 'package:guiautomotriz_mobile/features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart';
import 'package:guiautomotriz_mobile/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:guiautomotriz_mobile/features/notifications/presentation/providers/notifications_providers.dart';

class _FakeNotificationsRepository implements NotificationsRepository {
  final unreadResults = <Either<Failure, List<UserNotification>>>[];
  Either<Failure, void> markReadResult = const Right(null);
  Either<Failure, void> markAllResult = const Right(null);
  final requestedPages = <int>[];
  final markedIds = <String>[];
  int markAllCalls = 0;

  @override
  Future<Either<Failure, List<UserNotification>>> getUnread({
    int page = 1,
    int limit = 20,
  }) async {
    requestedPages.add(page);
    return unreadResults.removeAt(0);
  }

  @override
  Future<Either<Failure, void>> markRead(String id) async {
    markedIds.add(id);
    return markReadResult;
  }

  @override
  Future<Either<Failure, void>> markAllRead() async {
    markAllCalls++;
    return markAllResult;
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async => const Right(0);
}

UserNotification _fixture(int index) => UserNotification(
      id: 'n-$index',
      type: 'offer.new',
      title: 'Oferta $index',
      body: 'Mensaje $index',
      data: const {},
      isRead: false,
      createdAt: DateTime.utc(2026, 8, 14, 12, index % 60),
    );

NotificationsNotifier _subject(
  _FakeNotificationsRepository repository,
  void Function() invalidate,
) {
  return NotificationsNotifier(
    getUnread: GetUnreadNotificationsUseCase(repository),
    markRead: MarkNotificationReadUseCase(repository),
    markAllRead: MarkAllNotificationsReadUseCase(repository),
    invalidateCount: invalidate,
  );
}

void main() {
  test('initial load requests page one and exposes a complete page', () async {
    final repository = _FakeNotificationsRepository()
      ..unreadResults.add(Right(List.generate(20, _fixture)));
    final notifier = _subject(repository, () {});

    await notifier.loadInitial();

    expect(notifier.state.items, hasLength(20));
    expect(notifier.state.page, 1);
    expect(notifier.state.hasMore, isTrue);
    expect(notifier.state.isInitialLoading, isFalse);
    expect(repository.requestedPages, [1]);
  });

  test('initial failure exposes safe copy and no raw error', () async {
    final repository = _FakeNotificationsRepository()
      ..unreadResults.add(const Left(NetworkFailure(message: 'socket raw')));
    final notifier = _subject(repository, () {});

    await notifier.loadInitial();

    expect(notifier.state.items, isEmpty);
    expect(
      notifier.state.initialError,
      'No pudimos cargar tus notificaciones.',
    );
    expect(notifier.state.initialError, isNot(contains('socket')));
  });

  test('loadMore appends unique items and advances the page once', () async {
    final repository = _FakeNotificationsRepository()
      ..unreadResults.addAll([
        Right(List.generate(20, (index) => _fixture(index + 1))),
        Right([_fixture(20), _fixture(21)]),
      ]);
    final notifier = _subject(repository, () {});
    await notifier.loadInitial();

    await notifier.loadMore();

    expect(notifier.state.items, hasLength(21));
    expect(notifier.state.items.last.id, 'n-21');
    expect(notifier.state.page, 2);
    expect(notifier.state.hasMore, isFalse);
    expect(repository.requestedPages, [1, 2]);
  });

  test('successful markRead keeps the item until the page refreshes',
      () async {
    var invalidations = 0;
    final repository = _FakeNotificationsRepository()
      ..unreadResults.add(Right([_fixture(1)]));
    final notifier = _subject(repository, () => invalidations++);
    await notifier.loadInitial();

    final success = await notifier.markRead('n-1');

    expect(success, isTrue);
    expect(notifier.state.items.single.id, 'n-1');
    expect(notifier.state.markingIds, isEmpty);
    expect(repository.markedIds, ['n-1']);
    expect(invalidations, 1);
  });

  test('failed markRead keeps the item and exposes a recoverable error',
      () async {
    final repository = _FakeNotificationsRepository()
      ..unreadResults.add(Right([_fixture(1)]))
      ..markReadResult = const Left(NetworkFailure());
    final notifier = _subject(repository, () {});
    await notifier.loadInitial();

    final success = await notifier.markRead('n-1');

    expect(success, isFalse);
    expect(notifier.state.items.single.id, 'n-1');
    expect(notifier.state.markingIds, isEmpty);
    expect(notifier.state.actionError, isNotNull);

    notifier.clearActionError();
    expect(notifier.state.actionError, isNull);
  });

  test('successful markAllRead empties the list and invalidates the count',
      () async {
    var invalidations = 0;
    final repository = _FakeNotificationsRepository()
      ..unreadResults.add(Right([_fixture(1), _fixture(2)]));
    final notifier = _subject(repository, () => invalidations++);
    await notifier.loadInitial();

    final success = await notifier.markAllRead();

    expect(success, isTrue);
    expect(notifier.state.items, isEmpty);
    expect(notifier.state.isMarkingAll, isFalse);
    expect(repository.markAllCalls, 1);
    expect(invalidations, 1);
  });

  test('failed markAllRead preserves every unread item', () async {
    final repository = _FakeNotificationsRepository()
      ..unreadResults.add(Right([_fixture(1), _fixture(2)]))
      ..markAllResult = const Left(ServerFailure(message: 'falló'));
    final notifier = _subject(repository, () {});
    await notifier.loadInitial();

    final success = await notifier.markAllRead();

    expect(success, isFalse);
    expect(notifier.state.items.map((item) => item.id), ['n-1', 'n-2']);
    expect(notifier.state.isMarkingAll, isFalse);
    expect(notifier.state.actionError, 'falló');
  });
}
