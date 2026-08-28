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
import '../../domain/usecases/create_quote_usecase.dart';
import '../../domain/usecases/quote_offer_usecase.dart';
import '../../domain/usecases/buy_offer_usecase.dart';
import '../../domain/usecases/deliver_offer_usecase.dart';
import '../../domain/usecases/mark_as_read_usecase.dart';
import '../../domain/usecases/cancel_offer_usecase.dart';
import '../../domain/usecases/decline_match_usecase.dart';
import '../../domain/usecases/undo_decline_usecase.dart';
import '../../../../core/providers/current_user_provider.dart';
import '../../../../core/providers/cache_for.dart';
import '../../../../core/domain/enums/user_role.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/session/session_generation_provider.dart';

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

final cancelOfferUseCaseProvider = Provider<CancelOfferUseCase>((ref) {
  return CancelOfferUseCase(ref.watch(chatRepositoryProvider));
});

final declineMatchUseCaseProvider = Provider<DeclineMatchUseCase>((ref) {
  return DeclineMatchUseCase(ref.watch(chatRepositoryProvider));
});

final undoDeclineUseCaseProvider = Provider<UndoDeclineUseCase>((ref) {
  return UndoDeclineUseCase(ref.watch(chatRepositoryProvider));
});

// ── State Providers ──────────────────────────────────────────────────────────

/// Filtro activo para solicitudes de tiendas. `UNQUOTED` ya no es válido.
final storeStatusFilterProvider = StateProvider<String>((ref) {
  ref.watch(sessionGenerationProvider);
  return 'PENDING';
});

/// Mis compras abre en solicitudes activas. El usuario puede cambiar a
/// cotizadas, compradas o canceladas desde el grupo segmentado visible.
final consumerStatusFilterProvider = StateProvider<String>((ref) {
  ref.watch(sessionGenerationProvider);
  return 'OPEN';
});

/// Stable, targeted revisions for chat queries. Subscriptions live outside the
/// FutureProviders, so an event cannot be lost while a query invalidates and
/// rebuilds itself. Each query observes only the domains that affect it,
/// avoiding the previous all-lists-on-every-event refetch pattern.
final _chatRealtimeRevisionProvider =
    StateNotifierProvider<_ChatRealtimeRevisionNotifier, _ChatRealtimeRevision>(
        (ref) {
  ref.watch(sessionGenerationProvider);
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

/// Mensaje recibido después de la última carga REST de una conversación.
class ConversationRealtimeMessage {
  const ConversationRealtimeMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isRead;
}

/// Actualizaciones locales de un único card de conversación.
class ConversationRealtimeUpdate {
  const ConversationRealtimeUpdate(this.messages);

  final List<ConversationRealtimeMessage> messages;
}

/// Mantiene los eventos por conversación sin invalidar las consultas que
/// alimentan la pantalla completa. Cada card selecciona únicamente su entrada.
final _conversationRealtimeUpdatesProvider = StateNotifierProvider<
    _ConversationRealtimeUpdatesNotifier,
    Map<String, ConversationRealtimeUpdate>>((ref) {
  ref.watch(sessionGenerationProvider);
  return _ConversationRealtimeUpdatesNotifier(ref.watch(socketServiceProvider));
});

final conversationRealtimeUpdateProvider =
    Provider.family<ConversationRealtimeUpdate?, String>((ref, conversationId) {
  return ref.watch(
    _conversationRealtimeUpdatesProvider.select(
      (updates) => updates[conversationId],
    ),
  );
});

typedef LatestMessagePreviewKey = ({
  String conversationId,
  DateTime lastMessageAt,
  String lastMessage,
});

/// Completa la autoría que el endpoint de bandeja aún no entrega. Es
/// auto-dispose, se solicita sólo desde cards visibles que la necesitan y se
/// retiene brevemente para no repetir la petición al hacer scroll o cambiar de
/// pestaña. La identidad completa del preview forma parte de la clave para que
/// un refresh REST no reutilice la respuesta de un mensaje anterior.
final latestConversationMessageProvider = FutureProvider.autoDispose
    .family<ChatMessage?, LatestMessagePreviewKey>((ref, preview) async {
  ref.watch(sessionGenerationProvider);
  final repository = ref.watch(chatRepositoryProvider);
  final result = await repository.getLatestMessage(preview.conversationId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (message) {
      // Los fallos no quedan cacheados: al volver a materializar el card se
      // reintenta. Sólo una respuesta válida recibe la ventana de retención.
      ref.cacheFor(const Duration(minutes: 5));
      return message;
    },
  );
});

class _ConversationRealtimeUpdatesNotifier
    extends StateNotifier<Map<String, ConversationRealtimeUpdate>> {
  _ConversationRealtimeUpdatesNotifier(SocketService socketService)
      : super(const {}) {
    _messageSubscription = socketService.onMessage.listen(_handleMessage);
  }

  static const _maxMessagesPerConversation = 50;
  late final StreamSubscription<Map<String, dynamic>> _messageSubscription;

  void _handleMessage(Map<String, dynamic> data) {
    final id = data['id']?.toString();
    final conversationId = data['conversationId']?.toString();
    final senderId = data['senderId']?.toString();
    final content = data['content']?.toString();
    final createdAt = DateTime.tryParse(data['createdAt']?.toString() ?? '');

    if (id == null ||
        id.isEmpty ||
        conversationId == null ||
        conversationId.isEmpty ||
        senderId == null ||
        content == null ||
        createdAt == null) {
      return;
    }

    _record(
      conversationId,
      ConversationRealtimeMessage(
        id: id,
        senderId: senderId,
        content: content,
        createdAt: createdAt,
        isRead: data['read'] == true,
      ),
    );
  }

  /// Conserva la autoría al volver de un chat ya leído sin disparar otra
  /// consulta HTTP por cada card de la bandeja.
  void seedReadMessage(ChatMessage message) {
    _record(
      message.conversationId,
      ConversationRealtimeMessage(
        id: message.id,
        senderId: message.senderId,
        content: message.content,
        createdAt: message.createdAt,
        isRead: true,
      ),
    );
  }

  void _record(
    String conversationId,
    ConversationRealtimeMessage message,
  ) {
    final previous = state[conversationId]?.messages ?? const [];
    if (previous.any((current) => current.id == message.id)) return;

    final messages = <ConversationRealtimeMessage>[...previous, message]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    if (messages.length > _maxMessagesPerConversation) {
      messages.removeRange(0, messages.length - _maxMessagesPerConversation);
    }

    state = Map.unmodifiable({
      ...state,
      conversationId: ConversationRealtimeUpdate(List.unmodifiable(messages)),
    });
  }

  @override
  void dispose() {
    _messageSubscription.cancel();
    super.dispose();
  }
}

/// Combina la respuesta REST con los mensajes posteriores a esa respuesta.
/// Si el servidor ya incluyó un mensaje en una recarga manual, su timestamp
/// evita volver a contarlo como no leído.
ChatConversation applyRealtimeConversationUpdate(
  ChatConversation conversation,
  ConversationRealtimeUpdate? update, {
  required String currentUserId,
}) {
  if (update == null) return conversation;

  final freshMessages = update.messages
      .where(
        (message) => message.createdAt.isAfter(conversation.lastMessageAt),
      )
      .toList();
  if (freshMessages.isEmpty) {
    final latestKnown = update.messages.isEmpty ? null : update.messages.last;
    if (latestKnown == null ||
        latestKnown.createdAt.isBefore(conversation.lastMessageAt) ||
        latestKnown.content != conversation.lastMessage) {
      return conversation;
    }

    return conversation.withRealtimePreview(
      lastMessage: conversation.lastMessage,
      lastMessageIsFromMe: latestKnown.senderId == currentUserId,
      unreadCount: conversation.unreadCount,
      lastMessageAt: conversation.lastMessageAt,
    );
  }

  final latest = freshMessages.last;
  final unreadDelta = freshMessages
      .where(
        (message) => !message.isRead && message.senderId != currentUserId,
      )
      .length;

  return conversation.withRealtimePreview(
    lastMessage: latest.content,
    lastMessageIsFromMe: latest.senderId == currentUserId,
    unreadCount: conversation.unreadCount + unreadDelta,
    lastMessageAt: latest.createdAt,
  );
}

/// Aplica la autoría hidratada únicamente si corresponde al preview actual.
/// Comparar id lógico, contenido y fecha evita etiquetar un mensaje obsoleto
/// cuando REST y el socket se cruzan.
ChatConversation applyLatestMessageAuthorship(
  ChatConversation conversation,
  ChatMessage? latestMessage,
) {
  if (conversation.lastMessageIsFromMe != null || latestMessage == null) {
    return conversation;
  }

  final sameConversation =
      latestMessage.conversationId == conversation.realtimeConversationId;
  final sameContent = latestMessage.content == conversation.lastMessage;
  final sameTimestamp =
      latestMessage.createdAt.isAtSameMomentAs(conversation.lastMessageAt);
  if (!sameConversation || !sameContent || !sameTimestamp) {
    return conversation;
  }

  return conversation.withRealtimePreview(
    lastMessage: conversation.lastMessage,
    lastMessageIsFromMe: latestMessage.isFromMe,
    unreadCount: conversation.unreadCount,
    lastMessageAt: conversation.lastMessageAt,
  );
}

/// Solicitudes creadas por el consumidor. Viven en Compras, no en Chats.
final consumerRequestsProvider = FutureProvider<ChatThreadsResult>((ref) async {
  ref.watch(sessionGenerationProvider);
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
  ref.watch(sessionGenerationProvider);
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

final myConversationsProvider =
    FutureProvider<List<ChatConversation>>((ref) async {
  ref.watch(sessionGenerationProvider);
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

final chatConversationDetailsProvider = FutureProvider.autoDispose
    .family<ChatConversation, String>((ref, conversationId) async {
  ref.watch(sessionGenerationProvider);
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
  ref.watch(sessionGenerationProvider);
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
  final void Function(ChatMessage) _onLatestLoaded;
  StreamSubscription? _msgSub;
  StreamSubscription? _reconnectSub;

  ChatMessagesNotifier({
    required GetMessagesUseCase getMessagesUseCase,
    required SocketService socketService,
    required String conversationId,
    required String currentUserId,
    required void Function(ChatMessage) onLatestLoaded,
  })  : _getMessagesUseCase = getMessagesUseCase,
        _socketService = socketService,
        _conversationId = conversationId,
        _currentUserId = currentUserId,
        _onLatestLoaded = onLatestLoaded,
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
          if (messages.isNotEmpty) {
            final latest = messages.reduce(
              (current, candidate) => candidate.createdAt.isAfter(
                current.createdAt,
              )
                  ? candidate
                  : current,
            );
            _onLatestLoaded(latest);
          }
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
    onLatestLoaded:
        ref.read(_conversationRealtimeUpdatesProvider.notifier).seedReadMessage,
  );
});
