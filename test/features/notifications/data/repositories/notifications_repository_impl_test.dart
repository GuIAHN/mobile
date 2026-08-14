import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/error/failures.dart';
import 'package:guiautomotriz_mobile/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:guiautomotriz_mobile/features/notifications/data/models/user_notification_model.dart';
import 'package:guiautomotriz_mobile/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _MockDatasource extends Mock implements NotificationsRemoteDatasource {}

void main() {
  late _MockDatasource datasource;
  late NotificationsRepositoryImpl repository;

  final notification = UserNotificationModel(
    id: 'n-1',
    type: 'offer.new',
    title: 'Nueva oferta',
    body: 'Tienes una oferta',
    data: {},
    isRead: false,
    createdAt: DateTime.utc(2026, 8, 14, 12),
  );

  setUp(() {
    datasource = _MockDatasource();
    repository = NotificationsRepositoryImpl(datasource);
  });

  test('returns unread notifications received from the remote boundary',
      () async {
    when(
      () => datasource.getUnreadNotifications(page: 1, limit: 20),
    ).thenAnswer((_) async => [notification]);

    final result = await repository.getUnread(page: 1, limit: 20);

    result.fold(
      (failure) => fail('Expected notifications, got $failure'),
      (items) {
        expect(items, hasLength(1));
        expect(items.single, notification);
      },
    );
  });

  test('maps connection errors without exposing Dio to the domain', () async {
    when(
      () => datasource.getUnreadNotifications(page: 1, limit: 20),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: 'me/notifications'),
        type: DioExceptionType.connectionError,
      ),
    );

    final result = await repository.getUnread(page: 1, limit: 20);

    result.fold(
      (failure) => expect(failure, isA<NetworkFailure>()),
      (_) => fail('Expected NetworkFailure'),
    );
  });

  test('returns success only after the individual mutation completes',
      () async {
    when(() => datasource.markRead('n-1')).thenAnswer((_) async {});

    final result = await repository.markRead('n-1');

    expect(result.isRight(), isTrue);
  });

  test('returns success only after the bulk mutation completes', () async {
    when(datasource.markAllRead).thenAnswer((_) async {});

    final result = await repository.markAllRead();

    expect(result.isRight(), isTrue);
  });

  test('returns the unread count through the same failure boundary', () async {
    when(datasource.getUnreadCount).thenAnswer((_) async => 7);

    final result = await repository.getUnreadCount();

    result.fold(
      (failure) => fail('Expected count, got $failure'),
      (count) => expect(count, 7),
    );
  });
}
