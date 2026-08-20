import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/chat_threads_result.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/get_chat_threads_usecase.dart';
import '../../domain/usecases/get_conversations_usecase.dart';
import '../../domain/usecases/get_messages_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/create_quote_usecase.dart';
import '../../domain/usecases/quote_offer_usecase.dart';
import '../../domain/usecases/buy_offer_usecase.dart';
import '../../domain/usecases/deliver_offer_usecase.dart';
import '../../domain/usecases/mark_as_read_usecase.dart';
import '../../../../core/providers/current_user_provider.dart';
import '../../../../core/domain/enums/user_role.dart';
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

final getConversationsUseCaseProvider =
    Provider<GetConversationsUseCase>((ref) {
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

final quoteOfferUseCaseProvider = Provider<QuoteOfferUseCase>((ref) {
  return QuoteOfferUseCase(ref.watch(chatRepositoryProvider));
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

/// Filtro activo para consultas de tiendas (UNQUOTED, QUOTED, BOUGHT, DELIVERED, ALL).
final storeStatusFilterProvider = StateProvider<String>((ref) => 'UNQUOTED');

/// Filtro activo para consultas de consumidores (ALL, OPEN, WITH_OFFER, BOUGHT, CLOSED).
final consumerStatusFilterProvider = StateProvider<String>((ref) => 'ALL');

/// Stable, targeted revisions for chat queries. Subscriptions live outside the
/// FutureProviders, so an event cannot be lost while a query invalidates and
/// rebuilds itself. Each query observes only the domains that affect it,
/// avoiding the previous all-lists-on-every-event refetch pattern.
final _chatRealtimeRevisionProvider =
    StateNotifierProvider<_ChatRealtimeRevisionNotifier, _ChatRealtimeRevision>(
        (ref) {
  return _ChatRealtimeRevisionNotifier(ref.watch(socketServiceProvider));
});

class _ChatRealtimeRevision {
  const _ChatRealtimeRevision({
    this.consumerRequests = 0,
    this.storeSales = 0,
    this.conversations = 0,
    this.details = 0,
  });

  final int consumerRequests;
  final int storeSales;
  final int conversations;
  final int details;
}

class _ChatRealtimeRevisionNotifier
    extends StateNotifier<_ChatRealtimeRevision> {
  _ChatRealtimeRevisionNotifier(SocketService socketService)
      : _subscriptions = [],
        super(const _ChatRealtimeRevision()) {
    _subscriptions.addAll([
      socketService.onSearchMatched.listen((_) => _advance(storeSales: true)),
      socketService.onOfferUpdated.listen(
        (_) => _advance(
          consumerRequests: true,
          storeSales: true,
          conversations: true,
          details: true,
        ),
      ),
      socketService.onMessage.listen(
        (_) => _advance(
          consumerRequests: true,
          storeSales: true,
          conversations: true,
        ),
      ),
      socketService.onNotification.listen((event) {
        // Inquiry creation currently has no independent domain event on the
        // mobile contract, so its notification is the targeted invalidation.
        if (event['tipo'] == 'offer.inquiry') {
          _advance(
            consumerRequests: true,
            conversations: true,
            details: true,
          );
        }
      }),
      socketService.onReconnect.listen(
        (_) => _advance(
          consumerRequests: true,
          storeSales: true,
          conversations: true,
          details: true,
        ),
      ),
    ]);
  }

  final List<StreamSubscription<dynamic>> _subscriptions;

  void _advance({
    bool consumerRequests = false,
    bool storeSales = false,
    bool conversations = false,
    bool details = false,
  }) {
    state = _ChatRealtimeRevision(
      consumerRequests: state.consumerRequests + (consumerRequests ? 1 : 0),
      storeSales: state.storeSales + (storeSales ? 1 : 0),
      conversations: state.conversations + (conversations ? 1 : 0),
      details: state.details + (details ? 1 : 0),
    );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}

/// Solicitudes creadas por el consumidor. Viven en Compras, no en Chats.
final consumerRequestsProvider = FutureProvider<ChatThreadsResult>((ref) async {
  final useCase = ref.watch(getChatThreadsUseCaseProvider);
  ref.watch(
    _chatRealtimeRevisionProvider.select((value) => value.consumerRequests),
  );

  final result = await useCase(
    role: UserRole.consumer,
    statusFilter: ref.watch(consumerStatusFilterProvider),
  );
  return result.fold(
    (failure) => throw Exception(failure.message),
    (requests) => requests,
  );
});

/// Solicitudes visibles para la tienda. Constituyen su bandeja de Ventas.
final storeSalesRequestsProvider =
    FutureProvider<ChatThreadsResult>((ref) async {
  final useCase = ref.watch(getChatThreadsUseCaseProvider);
  ref.watch(
    _chatRealtimeRevisionProvider.select((value) => value.storeSales),
  );

  final result = await useCase(
    role: UserRole.store,
    statusFilter: ref.watch(storeStatusFilterProvider),
  );
  return result.fold(
    (failure) => throw Exception(failure.message),
    (requests) => requests,
  );
});

/// Alias transitorio para detalles existentes. La selección se basa solo en
/// STORE, no en `isProvider`, porque el endpoint de ventas pertenece a tiendas.
final chatThreadsProvider = FutureProvider<ChatThreadsResult>((ref) {
  final role = ref.watch(currentRoleProvider);
  return ref.watch(
    role.isStore
        ? storeSalesRequestsProvider.future
        : consumerRequestsProvider.future,
  );
});

final myConversationsProvider =
    FutureProvider<List<ChatConversation>>((ref) async {
  final repository = ref.watch(chatRepositoryProvider);
  ref.watch(
    _chatRealtimeRevisionProvider.select((value) => value.conversations),
  );

  final result = await repository.getMyConversations();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (conversations) => conversations,
  );
});

/// El indicador de chats se calcula desde conversaciones reales, no desde
/// solicitudes que casualmente tengan ofertas.
final hasUnreadChatThreadsProvider = Provider<bool>((ref) {
  final conversations = ref.watch(myConversationsProvider);
  return conversations.valueOrNull
          ?.any((conversation) => conversation.unreadCount > 0) ??
      false;
});

final chatConversationDetailsProvider = FutureProvider.autoDispose
    .family<ChatConversation, String>((ref, conversationId) async {
  final repository = ref.watch(chatRepositoryProvider);
  ref.watch(
    _chatRealtimeRevisionProvider.select((value) => value.details),
  );

  final result = await repository.getConversationDetails(conversationId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (conversation) => conversation,
  );
});

/// Conversaciones/ofertas dentro de una carpeta específica.
final chatConversationsProvider = FutureProvider.autoDispose
    .family<List<ChatConversation>, String>((ref, threadId) async {
  final useCase = ref.watch(getConversationsUseCaseProvider);
  ref.watch(
    _chatRealtimeRevisionProvider.select((value) => value.conversations),
  );

  final result = await useCase(threadId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (conversations) => conversations,
  );
});

// ── Messages Notifier ────────────────────────────────────────────────────────

class ChatMessagesNotifier
    extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final GetMessagesUseCase _getMessagesUseCase;
  final SocketService _socketService;
  final String _conversationId;
  final String _currentUserId;
  StreamSubscription? _msgSub;
  StreamSubscription? _reconnectSub;

  ChatMessagesNotifier({
    required GetMessagesUseCase getMessagesUseCase,
    required SocketService socketService,
    required String conversationId,
    required String currentUserId,
  })  : _getMessagesUseCase = getMessagesUseCase,
        _socketService = socketService,
        _conversationId = conversationId,
        _currentUserId = currentUserId,
        super(const AsyncValue.loading()) {
    loadMessages();
    _socketService.joinConversation(_conversationId);

    // Apply complete message payloads locally. This keeps an active chat at
    // zero HTTP reads per message while eventId/id de-duplication protects
    // against retries and multi-room delivery.
    _msgSub = _socketService.onMessage.listen((data) {
      if (data['conversationId'] != _conversationId) return;
      _appendMessage(data);
    });
    _reconnectSub = _socketService.onReconnect.listen((_) {
      loadMessages();
    });
  }

  Future<void> loadMessages() async {
    final result = await _getMessagesUseCase(_conversationId);
    if (!mounted) return;
    result.fold(
      (failure) {
        if (mounted) {
          state = AsyncValue.error(failure.message, StackTrace.current);
        }
      },
      (messages) {
        if (mounted) {
          state = AsyncValue.data(messages);
        }
      },
    );
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    final success = await _socketService.sendMessage(_conversationId, content);
    if (!success) {
      throw Exception(
          'Sin conexión al servidor de chat. Verifica tu red o recarga la app.');
    }
  }

  void _appendMessage(Map<String, dynamic> data) {
    final id = data['id']?.toString();
    final senderId = data['senderId']?.toString();
    final content = data['content']?.toString();
    final createdAt = DateTime.tryParse(data['createdAt']?.toString() ?? '');
    if (id == null ||
        id.isEmpty ||
        senderId == null ||
        content == null ||
        createdAt == null) {
      return;
    }

    final current = state.valueOrNull;
    if (current == null || current.any((message) => message.id == id)) return;
    final typeName = data['type']?.toString();
    final type = MessageType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => MessageType.text,
    );
    final message = ChatMessage(
      id: id,
      conversationId: _conversationId,
      senderId: senderId,
      senderName: data['senderName']?.toString() ?? 'Usuario',
      isFromMe: senderId == _currentUserId,
      content: content,
      type: type,
      createdAt: createdAt,
      isRead: data['read'] == true,
    );
    state = AsyncValue.data([message, ...current]);
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _reconnectSub?.cancel();
    _socketService.leaveConversation(_conversationId);
    super.dispose();
  }
}

final chatMessagesProvider = StateNotifierProvider.family
    .autoDispose<ChatMessagesNotifier, AsyncValue<List<ChatMessage>>, String>(
        (ref, conversationId) {
  return ChatMessagesNotifier(
    getMessagesUseCase: ref.watch(getMessagesUseCaseProvider),
    socketService: ref.watch(socketServiceProvider),
    conversationId: conversationId,
    currentUserId: ref.watch(currentUserProvider)?.id ?? '',
  );
});
