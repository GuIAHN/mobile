import 'dart:async';

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

  setUp(() {
    getMessages = _MockGetMessagesUseCase();
    socketService = _MockSocketService();
    notifierDisposed = false;
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
    );
  });

  tearDown(() async {
    if (!notifierDisposed) notifier.dispose();
    await messages.close();
    await reconnects.close();
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
