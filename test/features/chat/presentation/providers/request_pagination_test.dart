import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/service_type.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/user_role.dart';
import 'package:guiautomotriz_mobile/core/error/failures.dart';
import 'package:guiautomotriz_mobile/core/services/socket_service.dart';
import 'package:guiautomotriz_mobile/core/storage/secure_storage.dart';
import 'package:guiautomotriz_mobile/core/session/session_generation_provider.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_conversation.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_thread.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_threads_result.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/repositories/chat_repository.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/usecases/get_chat_threads_usecase.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/providers/chat_providers.dart';
import 'package:mocktail/mocktail.dart';

class _Threads extends Mock implements GetChatThreadsUseCase {}

class _Socket extends Mock implements SocketService {}

class _Repository extends Mock implements ChatRepository {}

class _Storage extends Mock implements SecureStorage {}

void main() {
  late _Socket socket;
  late StreamController<Map<String, dynamic>> offers;
  setUp(() {
    socket = _Socket();
    offers = StreamController.broadcast();
    when(() => socket.onOfferUpdated).thenAnswer((_) => offers.stream);
    when(() => socket.onSearchMatched).thenAnswer((_) => const Stream.empty());
    when(() => socket.onNotification).thenAnswer((_) => const Stream.empty());
    when(() => socket.onMessage).thenAnswer((_) => const Stream.empty());
    when(() => socket.onReconnect).thenAnswer((_) => const Stream.empty());
  });
  tearDown(() => offers.close());

  ChatThread thread(String id) => ChatThread(
      id: id,
      title: id,
      requestType: ServiceType.spareParts,
      unreadCount: 0,
      conversationCount: 0,
      lastActivityAt: DateTime.utc(2026, 11, 3));

  test(
      'filter, realtime and session changes reset pages and discard the old filter response',
      () async {
    final useCase = _Threads();
    var version = 1;
    final pending = Completer<Either<Failure, ChatThreadsResult>>();
    when(() => useCase(
        role: UserRole.consumer,
        statusFilter: any(named: 'statusFilter'),
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'))).thenAnswer((call) async {
      final filter = call.namedArguments[#statusFilter] as String;
      final page = call.namedArguments[#page] as int;
      if (filter == 'ALL' && page == 2) return pending.future;
      return Right(
          ChatThreadsResult(threads: [thread('$filter-$version')], total: 43));
    });
    final container = ProviderContainer(overrides: [
      socketServiceProvider.overrideWithValue(socket),
      getChatThreadsUseCaseProvider.overrideWithValue(useCase),
    ]);
    addTearDown(container.dispose);
    final provider = paginatedRequestsProvider('consumer');
    container.listen(provider, (_, __) {});
    await container.read(provider.future);
    final oldPage = container.read(provider.notifier).loadMore();
    container.read(consumerStatusFilterProvider.notifier).state = 'WITH_OFFER';
    await container.read(provider.future);
    pending.complete(Right(
        ChatThreadsResult(threads: [thread('stale')], page: 2, total: 43)));
    await oldPage;
    expect(
        container.read(provider).requireValue.items.single.id, 'WITH_OFFER-1');
    version = 2;
    offers.add({'offerId': 'offer', 'status': 'SENT'});
    await pumpEventQueue();
    expect((await container.read(provider.future)).items.single.id,
        'WITH_OFFER-2');
    version = 3;
    container.read(sessionGenerationProvider.notifier).state++;
    expect((await container.read(provider.future)).items.single.id, 'ALL-3');
    expect(container.read(provider).requireValue.page, 1);
  });

  test(
      'a fully hidden conversation page still allows loading the next server page',
      () async {
    final repository = _Repository();
    final storage = _Storage();
    ChatConversation conversation(int i, {bool handled = false}) =>
        ChatConversation(
            id: 'c$i',
            threadId: 'r$i',
            participantName: 'Cliente',
            lastMessage: '',
            unreadCount: 0,
            lastMessageAt: DateTime.utc(2026, 11, 3),
            offerStatus: handled ? 'DELIVERED' : 'SENT',
            hasReviewed: handled);
    when(() => repository.getMyConversations()).thenAnswer((_) async =>
        Right(List.generate(20, (i) => conversation(i, handled: true))));
    when(() => repository.getMyConversations(page: 2, pageSize: 20))
        .thenAnswer((_) async => Right([conversation(20)]));
    final container = ProviderContainer(overrides: [
      socketServiceProvider.overrideWithValue(socket),
      chatRepositoryProvider.overrideWithValue(repository),
      secureStorageProvider.overrideWithValue(storage),
    ]);
    addTearDown(container.dispose);
    final provider = paginatedConversationsProvider('inbox');
    container.listen(provider, (_, __) {});
    final first = await container.read(provider.future);
    expect(first.items, isEmpty);
    expect(first.hasMore, isTrue);
    await container.read(provider.notifier).loadMore();
    final last = container.read(provider).requireValue;
    expect(last.items.single.id, 'c20');
    expect(last.hasMore, isFalse);
  });
}
