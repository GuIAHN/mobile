import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/chat_thread.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/get_chat_threads_usecase.dart';
import '../../domain/usecases/get_conversations_usecase.dart';
import '../../domain/usecases/get_messages_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/create_quote_usecase.dart';
import '../../domain/usecases/buy_offer_usecase.dart';
import '../../domain/usecases/deliver_offer_usecase.dart';
import '../../domain/usecases/mark_as_read_usecase.dart';
import '../../../../core/providers/current_user_provider.dart';
import '../../../../core/services/socket_service.dart';

// ── Dependency Providers ─────────────────────────────────────────────────────

import '../../../../core/network/dio_client.dart';

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ChatRemoteDataSource(
    dioClient,
    () => ref.read(currentUserProvider)?.id ?? '',
  );
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final dataSource = ref.watch(chatRemoteDataSourceProvider);
  return ChatRepositoryImpl(
    remoteDataSource: dataSource,
    getCurrentRole: () => ref.read(currentRoleProvider),
  );
});

final getChatThreadsUseCaseProvider = Provider<GetChatThreadsUseCase>((ref) {
  return GetChatThreadsUseCase(ref.watch(chatRepositoryProvider));
});

final getConversationsUseCaseProvider = Provider<GetConversationsUseCase>((ref) {
  return GetConversationsUseCase(ref.watch(chatRepositoryProvider));
});

final getMessagesUseCaseProvider = Provider<GetMessagesUseCase>((ref) {
  return GetMessagesUseCase(ref.watch(chatRepositoryProvider));
});

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.watch(chatRepositoryProvider));
});

final createQuoteUseCaseProvider = Provider<CreateQuoteUseCase>((ref) {
  return CreateQuoteUseCase(ref.watch(chatRepositoryProvider));
});

final buyOfferUseCaseProvider = Provider<BuyOfferUseCase>((ref) {
  return BuyOfferUseCase(ref.watch(chatRepositoryProvider));
});

final deliverOfferUseCaseProvider = Provider<DeliverOfferUseCase>((ref) {
  return DeliverOfferUseCase(ref.watch(chatRepositoryProvider));
});

final markAsReadUseCaseProvider = Provider<MarkAsReadUseCase>((ref) {
  return MarkAsReadUseCase(ref.watch(chatRepositoryProvider));
});

// ── State Providers ──────────────────────────────────────────────────────────

/// Hilos o carpetas activas.
final chatThreadsProvider = FutureProvider<List<ChatThread>>((ref) async {
  final useCase = ref.watch(getChatThreadsUseCaseProvider);
  final socketService = ref.watch(socketServiceProvider);

  final sub1 = socketService.onSearchMatched.listen((_) {
    ref.invalidateSelf();
  });
  final sub2 = socketService.onMessage.listen((_) {
    ref.invalidateSelf();
  });
  final sub3 = socketService.onOfferUpdated.listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() {
    sub1.cancel();
    sub2.cancel();
    sub3.cancel();
  });

  final result = await useCase();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (threads) => threads,
  );
});

final myConversationsProvider = FutureProvider<List<ChatConversation>>((ref) async {
  final repository = ref.watch(chatRepositoryProvider);
  final socketService = ref.watch(socketServiceProvider);
  
  final sub = socketService.onMessage.listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => sub.cancel());

  final result = await repository.getMyConversations();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (conversations) => conversations,
  );
});

final chatConversationDetailsProvider = FutureProvider.family<ChatConversation, String>((ref, conversationId) async {
  final repository = ref.watch(chatRepositoryProvider);
  final socketService = ref.watch(socketServiceProvider);

  final sub1 = socketService.onOfferUpdated.listen((_) {
    ref.invalidateSelf();
  });
  final sub2 = socketService.onMessage.listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() {
    sub1.cancel();
    sub2.cancel();
  });

  final result = await repository.getConversationDetails(conversationId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (conversation) => conversation,
  );
});

/// Conversaciones/ofertas dentro de una carpeta específica.
final chatConversationsProvider = FutureProvider.family<List<ChatConversation>, String>((ref, threadId) async {
  final useCase = ref.watch(getConversationsUseCaseProvider);
  final socketService = ref.watch(socketServiceProvider);

  final sub1 = socketService.onOfferUpdated.listen((_) {
    ref.invalidateSelf();
  });
  final sub2 = socketService.onMessage.listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() {
    sub1.cancel();
    sub2.cancel();
  });

  final result = await useCase(threadId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (conversations) => conversations,
  );
});

// ── Messages Notifier ────────────────────────────────────────────────────────

class ChatMessagesNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final GetMessagesUseCase _getMessagesUseCase;
  final SocketService _socketService;
  final String _conversationId;

  ChatMessagesNotifier({
    required GetMessagesUseCase getMessagesUseCase,
    required SocketService socketService,
    required String conversationId,
  })  : _getMessagesUseCase = getMessagesUseCase,
        _socketService = socketService,
        _conversationId = conversationId,
        super(const AsyncValue.loading()) {
    loadMessages();
    _socketService.joinConversation(_conversationId);
    
    // Escuchar nuevos mensajes y actualizaciones de oferta
    _socketService.onMessage.listen((data) {
      if (data['conversationId'] == _conversationId || data['conversationId'] == null) {
        loadMessages();
      }
    });

    _socketService.onOfferUpdated.listen((_) {
      loadMessages();
    });
  }

  Future<void> loadMessages() async {
    final result = await _getMessagesUseCase(_conversationId);
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (messages) => state = AsyncValue.data(messages),
    );
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    try {
      final success = await _socketService.sendMessage(_conversationId, content);
      if (!success) {
        throw Exception('Sin conexión al servidor de chat. Verifica tu red o recarga la app.');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}

final chatMessagesProvider = StateNotifierProvider.family.autoDispose<
    ChatMessagesNotifier, AsyncValue<List<ChatMessage>>, String>((ref, conversationId) {
  return ChatMessagesNotifier(
    getMessagesUseCase: ref.watch(getMessagesUseCaseProvider),
    socketService: ref.watch(socketServiceProvider),
    conversationId: conversationId,
  );
});
