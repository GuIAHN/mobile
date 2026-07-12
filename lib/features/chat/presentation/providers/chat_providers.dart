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
import '../../../../core/providers/current_user_provider.dart';

// ── Dependency Providers ─────────────────────────────────────────────────────

import '../../../../core/network/dio_client.dart';

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ChatRemoteDataSource(dioClient);
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

// ── State Providers ──────────────────────────────────────────────────────────

/// Hilos o carpetas activas.
final chatThreadsProvider = FutureProvider.autoDispose<List<ChatThread>>((ref) async {
  final useCase = ref.watch(getChatThreadsUseCaseProvider);
  final result = await useCase();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (threads) => threads,
  );
});

/// Conversaciones/ofertas dentro de una carpeta específica.
final chatConversationsProvider = FutureProvider.autoDispose.family<List<ChatConversation>, String>((ref, threadId) async {
  final useCase = ref.watch(getConversationsUseCaseProvider);
  final result = await useCase(threadId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (conversations) => conversations,
  );
});

// ── Messages Notifier ────────────────────────────────────────────────────────

class ChatMessagesNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final GetMessagesUseCase _getMessagesUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final String _conversationId;

  ChatMessagesNotifier({
    required GetMessagesUseCase getMessagesUseCase,
    required SendMessageUseCase sendMessageUseCase,
    required String conversationId,
  })  : _getMessagesUseCase = getMessagesUseCase,
        _sendMessageUseCase = sendMessageUseCase,
        _conversationId = conversationId,
        super(const AsyncValue.loading()) {
    loadMessages();
  }

  Future<void> loadMessages() async {
    state = const AsyncValue.loading();
    final result = await _getMessagesUseCase(_conversationId);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (messages) => AsyncValue.data(messages),
    );
  }

  Future<bool> sendMessage(String content) async {
    if (content.trim().isEmpty) return false;
    
    final result = await _sendMessageUseCase(_conversationId, content);
    return result.fold(
      (failure) => false,
      (newMessage) {
        state.whenData((currentList) {
          state = AsyncValue.data([...currentList, newMessage]);
        });
        return true;
      },
    );
  }
}

final chatMessagesProvider = StateNotifierProvider.family.autoDispose<
    ChatMessagesNotifier, AsyncValue<List<ChatMessage>>, String>((ref, conversationId) {
  return ChatMessagesNotifier(
    getMessagesUseCase: ref.watch(getMessagesUseCaseProvider),
    sendMessageUseCase: ref.watch(sendMessageUseCaseProvider),
    conversationId: conversationId,
  );
});
