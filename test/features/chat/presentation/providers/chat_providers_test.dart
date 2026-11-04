import 'dart:async';

import 'package:guiautomotriz_mobile/core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/services/socket_service.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_message.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/usecases/get_messages_usecase.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/providers/chat_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetMessagesUseCase extends Mock implements GetMessagesUseCase {}

class _MockSocketService extends Mock implements SocketService {}

void main() {
  late _MockGetMessagesUseCase getMessages;
  late _MockSocketService socketService;
  late ChatMessagesNotifier notifier;
  late StreamController<Map<String, dynamic>> messages;
  late StreamController<void> reconnects;
  var notifierDisposed = false;
  late List<MessageHistoryState> history;

  setUp(() {
    getMessages = _MockGetMessagesUseCase();
    socketService = _MockSocketService();
    notifierDisposed = false;
    history = [];
    messages = StreamController<Map<String, dynamic>>.broadcast();
    reconnects = StreamController<void>.broadcast();

    when(() => getMessages(any())).thenAnswer(
      (_) async => const Right(<ChatMessage>[]),
    );
    when(() => socketService.onMessage).thenAnswer(
      (_) => messages.stream,
    );
    when(() => socketService.onReconnect).thenAnswer((_) => reconnects.stream);
    when(() => socketService.joinConversation(any())).thenReturn(null);
    when(() => socketService.leaveConversation(any())).thenReturn(null);

    notifier = ChatMessagesNotifier(
      getMessagesUseCase: getMessages,
      socketService: socketService,
      conversationId: 'conversation-1',
      currentUserId: 'current-user',
      onLatestLoaded: (_) {},
      onHistoryChanged: history.add,
    );
  });

  tearDown(() async {
    if (!notifierDisposed) notifier.dispose();
    await messages.close();
    await reconnects.close();
  });

  List<ChatMessage> batch(int start, int length) => List.generate(
      length,
      (i) => ChatMessage(
          id: 'm${start + i}',
          conversationId: 'conversation-1',
          senderId: 'other',
          senderName: 'Cliente',
          isFromMe: false,
          content: 'Mensaje ${start + i}',
          createdAt: DateTime.utc(2026, 11, 3)
              .subtract(Duration(minutes: start + i))));

  test(
      'loads history past 30 messages, keeps realtime arrivals, and stops at the end',
      () async {
    await pumpEventQueue();
    final first = batch(0, 30);
    when(() => getMessages('conversation-1'))
        .thenAnswer((_) async => Right(first));
    await notifier.loadMessages();
    expect(history.last.hasMore, isTrue);
    final pending = Completer<Either<Failure, List<ChatMessage>>>();
    when(() => getMessages('conversation-1',
        before: first.last.createdAt,
        limit: 30)).thenAnswer((_) => pending.future);
    final loading = notifier.loadOlder();
    await notifier.loadOlder();
    messages.add({
      'id': 'realtime',
      'conversationId': 'conversation-1',
      'senderId': 'other',
      'content': 'Nuevo',
      'createdAt': '2026-11-03T00:01:00Z'
    });
    await pumpEventQueue();
    pending.complete(Right(batch(30, 13)));
    await loading;
    expect(notifier.state.value!, hasLength(44));
    expect(notifier.state.value!.first.id, 'realtime');
    expect(notifier.state.value!.last.id, 'm42');
    expect(history.last.hasMore, isFalse);
    verify(() => getMessages('conversation-1',
        before: first.last.createdAt, limit: 30)).called(1);
  });

  test('history failure keeps loaded messages and retries the same cursor',
      () async {
    await pumpEventQueue();
    final first = batch(0, 30);
    when(() => getMessages('conversation-1'))
        .thenAnswer((_) async => Right(first));
    await notifier.loadMessages();
    when(() => getMessages('conversation-1',
            before: first.last.createdAt, limit: 30))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'offline')));
    await notifier.loadOlder();
    expect(notifier.state.value!, hasLength(30));
    expect(history.last.error, 'offline');
    when(() => getMessages('conversation-1',
        before: first.last.createdAt,
        limit: 30)).thenAnswer((_) async => Right(batch(30, 1)));
    await notifier.loadOlder();
    expect(notifier.state.value!, hasLength(31));
    expect(history.last.error, isNull);
  });

  test(
      'refresh ignores an old history response and preserves already loaded history',
      () async {
    await pumpEventQueue();
    final first = batch(0, 30);
    when(() => getMessages('conversation-1'))
        .thenAnswer((_) async => Right(first));
    await notifier.loadMessages();
    final pending = Completer<Either<Failure, List<ChatMessage>>>();
    when(() => getMessages('conversation-1',
        before: first.last.createdAt,
        limit: 30)).thenAnswer((_) => pending.future);
    final older = notifier.loadOlder();
    await notifier.loadMessages();
    pending.complete(Right(batch(30, 13)));
    await older;
    expect(notifier.state.value!, hasLength(30));
    when(() => getMessages('conversation-1',
        before: first.last.createdAt,
        limit: 30)).thenAnswer((_) async => Right(batch(30, 13)));
    await notifier.loadOlder();
    await notifier.loadMessages();
    expect(notifier.state.value!, hasLength(43));
  });

  test(
      'reconnection bridges more than 30 new messages without skipping the middle',
      () async {
    await pumpEventQueue();
    final initial = batch(60, 30);
    when(() => getMessages('conversation-1'))
        .thenAnswer((_) async => Right(initial));
    await notifier.loadMessages();
    final latest = batch(0, 30);
    final middle = batch(30, 30);
    when(() => getMessages('conversation-1'))
        .thenAnswer((_) async => Right(latest));
    when(() => getMessages('conversation-1',
        before: latest.last.createdAt,
        limit: 30)).thenAnswer((_) async => Right(middle));
    when(() => getMessages('conversation-1',
        before: middle.last.createdAt,
        limit: 30)).thenAnswer((_) async => Right(initial));
    await notifier.loadMessages();
    expect(notifier.state.value!.map((m) => m.id),
        List.generate(90, (i) => 'm$i'));
  });

  test('preserves the typed realtime rejection for presentation logic',
      () async {
    const rejection = RealtimeRequestException(
      'CONTENT_REJECTED',
      'No se permite compartir datos de contacto ni enlaces externos.',
    );
    when(
      () => socketService.sendMessage('conversation-1', 'mensaje'),
    ).thenAnswer((_) async => throw rejection);

    Object? captured;
    try {
      await notifier.sendMessage('mensaje');
    } catch (error) {
      captured = error;
    }

    expect(captured, same(rejection));
    expect((captured! as RealtimeRequestException).code, 'CONTENT_REJECTED');
  });

  test('applies a complete message locally exactly once without an HTTP read',
      () async {
    await pumpEventQueue();
    final payload = <String, dynamic>{
      'id': 'message-1',
      'conversationId': 'conversation-1',
      'senderId': 'current-user',
      'senderName': 'Carlos',
      'content': 'Hola',
      'type': 'text',
      'read': false,
      'createdAt': '2026-08-20T00:00:00.000Z',
    };

    messages.add(payload);
    messages.add(payload);
    await pumpEventQueue();

    expect(notifier.state.value, hasLength(1));
    expect(notifier.state.value!.single.id, 'message-1');
    expect(notifier.state.value!.single.isFromMe, isTrue);
    verify(() => getMessages('conversation-1')).called(1);
  });

  test('leaves the room on dispose', () async {
    await pumpEventQueue();
    notifier.dispose();
    notifierDisposed = true;

    verify(() => socketService.leaveConversation('conversation-1')).called(1);
  });
}
