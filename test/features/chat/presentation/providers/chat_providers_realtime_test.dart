import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/user_role.dart';
import 'package:guiautomotriz_mobile/core/services/socket_service.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_threads_result.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/usecases/get_chat_threads_usecase.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/providers/chat_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockSocketService extends Mock implements SocketService {}

class _MockGetChatThreadsUseCase extends Mock
    implements GetChatThreadsUseCase {}

void main() {
  test('store sales refresh automatically after the socket reconnects',
      () async {
    final socket = _MockSocketService();
    final getThreads = _MockGetChatThreadsUseCase();
    final connected = StreamController<void>.broadcast();
    final matched = StreamController<Map<String, dynamic>>.broadcast();
    final offers = StreamController<Map<String, dynamic>>.broadcast();
    final messages = StreamController<Map<String, dynamic>>.broadcast();
    addTearDown(connected.close);
    addTearDown(matched.close);
    addTearDown(offers.close);
    addTearDown(messages.close);

    when(() => socket.onConnected).thenAnswer((_) => connected.stream);
    when(() => socket.onSearchMatched).thenAnswer((_) => matched.stream);
    when(() => socket.onOfferUpdated).thenAnswer((_) => offers.stream);
    when(() => socket.onMessage).thenAnswer((_) => messages.stream);
    when(
      () => getThreads(
        role: UserRole.store,
        statusFilter: 'UNQUOTED',
      ),
    ).thenAnswer(
      (_) async => const Right(
        ChatThreadsResult(threads: [], total: 0),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        socketServiceProvider.overrideWithValue(socket),
        getChatThreadsUseCaseProvider.overrideWithValue(getThreads),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      storeSalesRequestsProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await container.read(storeSalesRequestsProvider.future);
    verify(
      () => getThreads(
        role: UserRole.store,
        statusFilter: 'UNQUOTED',
      ),
    ).called(1);

    connected.add(null);
    await pumpEventQueue();
    await container.read(storeSalesRequestsProvider.future);

    verify(
      () => getThreads(
        role: UserRole.store,
        statusFilter: 'UNQUOTED',
      ),
    ).called(1);
  });

  test('store sales refresh after every incoming chat message', () async {
    final socket = _MockSocketService();
    final getThreads = _MockGetChatThreadsUseCase();
    final connected = StreamController<void>.broadcast();
    final matched = StreamController<Map<String, dynamic>>.broadcast();
    final offers = StreamController<Map<String, dynamic>>.broadcast();
    final messages = StreamController<Map<String, dynamic>>.broadcast();
    addTearDown(connected.close);
    addTearDown(matched.close);
    addTearDown(offers.close);
    addTearDown(messages.close);

    when(() => socket.onConnected).thenAnswer((_) => connected.stream);
    when(() => socket.onSearchMatched).thenAnswer((_) => matched.stream);
    when(() => socket.onOfferUpdated).thenAnswer((_) => offers.stream);
    when(() => socket.onMessage).thenAnswer((_) => messages.stream);
    when(
      () => getThreads(
        role: UserRole.store,
        statusFilter: 'UNQUOTED',
      ),
    ).thenAnswer(
      (_) async => const Right(
        ChatThreadsResult(threads: [], total: 0),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        socketServiceProvider.overrideWithValue(socket),
        getChatThreadsUseCaseProvider.overrideWithValue(getThreads),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      storeSalesRequestsProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await container.read(storeSalesRequestsProvider.future);

    messages.add(const {
      'conversationId': 'conversation-1',
      'content': 'Primer mensaje',
    });
    await pumpEventQueue();
    await container.read(storeSalesRequestsProvider.future);

    messages.add(const {
      'conversationId': 'conversation-1',
      'content': 'Último mensaje',
    });
    await pumpEventQueue();
    await container.read(storeSalesRequestsProvider.future);

    verify(
      () => getThreads(
        role: UserRole.store,
        statusFilter: 'UNQUOTED',
      ),
    ).called(3);
  });
}
