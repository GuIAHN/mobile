import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/error/failures.dart';
import 'package:guiautomotriz_mobile/features/notifications/domain/entities/user_notification.dart';
import 'package:guiautomotriz_mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:guiautomotriz_mobile/features/notifications/presentation/pages/notifications_page.dart';
import 'package:guiautomotriz_mobile/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:guiautomotriz_mobile/features/notifications/presentation/widgets/notification_card_skeleton.dart';
import 'package:guiautomotriz_mobile/features/notifications/presentation/widgets/notification_detail_sheet.dart';
import 'package:guiautomotriz_mobile/shared/widgets/app_notification_host.dart';

class _FakeNotificationsRepository implements NotificationsRepository {
  Future<Either<Failure, List<UserNotification>>> Function(int page, int limit)?
      onGetUnread;
  Future<Either<Failure, void>> Function(String id)? onMarkRead;
  Future<Either<Failure, void>> Function()? onMarkAllRead;
  final requestedPages = <int>[];
  final markedIds = <String>[];
  int markAllCalls = 0;

  @override
  Future<Either<Failure, List<UserNotification>>> getUnread({
    int page = 1,
    int limit = 20,
  }) {
    requestedPages.add(page);
    return onGetUnread?.call(page, limit) ??
        Future.value(const Right(<UserNotification>[]));
  }

  @override
  Future<Either<Failure, void>> markRead(String id) {
    markedIds.add(id);
    return onMarkRead?.call(id) ?? Future.value(const Right(null));
  }

  @override
  Future<Either<Failure, void>> markAllRead() {
    markAllCalls++;
    return onMarkAllRead?.call() ?? Future.value(const Right(null));
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async => const Right(0);
}

UserNotification _fixture(
  int index, {
  String? body,
}) {
  return UserNotification(
    id: 'n-$index',
    type: index.isEven ? 'message.new' : 'offer.new',
    title: index == 1 ? 'Nueva oferta' : 'Notificación $index',
    body: body ?? 'Contenido de la notificación $index',
    data: const {},
    isRead: false,
    createdAt: DateTime.utc(2026, 8, 14, 12, index % 60),
  );
}

Widget _subject(
  _FakeNotificationsRepository repository, {
  double textScale = 1,
  bool disableAnimations = false,
}) {
  return ProviderScope(
    overrides: [
      notificationsRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: child!,
      ),
      home: const AppNotificationHost(
        child: NotificationsPage(),
      ),
    ),
  );
}

Future<void> _pumpResolved(
  WidgetTester tester,
  _FakeNotificationsRepository repository, {
  double textScale = 1,
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    _subject(
      repository,
      textScale: textScale,
      disableAnimations: disableAnimations,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  testWidgets('shows four geometry-matched cards during the initial request',
      (tester) async {
    final pending = Completer<Either<Failure, List<UserNotification>>>();
    final repository = _FakeNotificationsRepository()
      ..onGetUnread = (_, __) => pending.future;

    await tester.pumpWidget(_subject(repository));
    await tester.pump();

    expect(find.byType(NotificationCardSkeleton), findsNWidgets(4));
    expect(find.text('Notificaciones'), findsOneWidget);
  });

  testWidgets('shows a safe retryable error without technical details',
      (tester) async {
    final repository = _FakeNotificationsRepository()
      ..onGetUnread = (_, __) async =>
          const Left(NetworkFailure(message: 'SocketException raw'));

    await _pumpResolved(tester, repository);

    expect(find.text('No pudimos cargar tus notificaciones.'), findsOneWidget);
    expect(find.textContaining('SocketException'), findsNothing);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('shows a refreshable up-to-date state when nothing is pending',
      (tester) async {
    final repository = _FakeNotificationsRepository();

    await _pumpResolved(tester, repository);

    expect(find.text('Estás al día'), findsOneWidget);
    expect(find.text('No tienes notificaciones sin leer.'), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.text('Marcar todas'), findsNothing);
  });

  testWidgets('opens the complete detail then removes a confirmed read item',
      (tester) async {
    final longBody = List.generate(
      50,
      (index) => 'Información ${index + 1}.',
    ).join(' ');
    var listCalls = 0;
    final repository = _FakeNotificationsRepository()
      ..onGetUnread = (_, __) async {
        listCalls++;
        return Right(listCalls == 1 ? [_fixture(1, body: longBody)] : []);
      };

    await _pumpResolved(tester, repository);
    expect(find.text('1 pendiente'), findsOneWidget);

    await tester.tap(
      find.bySemanticsLabel('Abrir y marcar como leída: Nueva oferta'),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(NotificationDetailSheet),
        matching: find.text(longBody),
      ),
      findsOneWidget,
    );
    expect(repository.markedIds, ['n-1']);
    expect(find.byKey(const Key('notification-card-n-1')), findsOneWidget);

    await tester.tap(
      find.bySemanticsLabel('Cerrar detalle de notificación'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Estás al día'), findsOneWidget);
    expect(repository.requestedPages, [1, 1]);
  }, semanticsEnabled: true);

  testWidgets('keeps an item unread when its PATCH fails', (tester) async {
    final repository = _FakeNotificationsRepository();
    repository.onGetUnread = (_, __) async => Right([_fixture(1)]);
    repository.onMarkRead = (_) async => const Left(NetworkFailure());

    await _pumpResolved(tester, repository);
    await tester.tap(
      find.bySemanticsLabel('Abrir y marcar como leída: Nueva oferta'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(
      find.bySemanticsLabel('Cerrar detalle de notificación'),
    );
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byKey(const Key('notification-card-n-1')), findsOneWidget);
    expect(find.text('Sin conexión a internet.'), findsOneWidget);
    expect(repository.requestedPages, [1]);
  }, semanticsEnabled: true);

  testWidgets('marks every notification read only after bulk success',
      (tester) async {
    final repository = _FakeNotificationsRepository()
      ..onGetUnread = (_, __) async => Right([_fixture(1), _fixture(2)]);

    await _pumpResolved(tester, repository);
    expect(find.text('2 pendientes'), findsOneWidget);

    await tester.tap(find.text('Marcar todas'));
    await tester.pumpAndSettle();

    expect(repository.markAllCalls, 1);
    expect(find.text('Estás al día'), findsOneWidget);
  });

  testWidgets('requests the next page near the end and deduplicates it',
      (tester) async {
    final repository = _FakeNotificationsRepository()
      ..onGetUnread = (page, __) async => Right(
            page == 1
                ? List.generate(20, (index) => _fixture(index + 1))
                : [_fixture(20), _fixture(21)],
          );

    await _pumpResolved(tester, repository);
    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(repository.requestedPages, [1, 2]);
    expect(find.byKey(const Key('notification-card-n-21')), findsOneWidget);
  });

  testWidgets('fits small and large phones at 200% text with 48 dp actions',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final size in const [Size(320, 700), Size(430, 932)]) {
      tester.view.physicalSize = size;
      final repository = _FakeNotificationsRepository()
        ..onGetUnread = (_, __) async => Right([_fixture(1)]);

      await _pumpResolved(
        tester,
        repository,
        textScale: 2,
        disableAnimations: true,
      );

      expect(tester.takeException(), isNull);
      expect(
        tester
            .getSize(find.byKey(const Key('notifications-back-button')))
            .height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester
            .getSize(find.byKey(const Key('notifications-mark-all-button')))
            .height,
        greaterThanOrEqualTo(48),
      );
    }
  });
}
