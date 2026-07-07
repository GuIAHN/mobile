import '../models/chat_thread_model.dart';
import '../models/chat_conversation_model.dart';
import '../models/chat_message_model.dart';
import '../../domain/entities/chat_message.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../../../../core/domain/enums/user_role.dart';

class ChatRemoteDataSource {
  // In-memory mock database to allow live interactions (adding messages, quotes)
  static final List<ChatThreadModel> _threads = [
    ChatThreadModel(
      id: 'thread_1',
      title: 'Kit de Embrague Toyota Hilux 2018',
      requestType: ServiceType.spareParts,
      unreadCount: 2,
      conversationCount: 3,
      lastActivityAt: DateTime.now().subtract(const Duration(minutes: 5)),
      clientName: 'Juan Pérez (Taller)',
      clientId: 'client_juan',
      fotoUrl: 'https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&w=500&q=80',
    ),
    ChatThreadModel(
      id: 'thread_2',
      title: 'Pastillas de Freno Delanteras Corolla 2015',
      requestType: ServiceType.spareParts,
      unreadCount: 0,
      conversationCount: 1,
      lastActivityAt: DateTime.now().subtract(const Duration(hours: 2)),
      clientName: 'María Rodríguez (Consumidor)',
      clientId: 'client_maria',
      fotoUrl: null,
    ),
    ChatThreadModel(
      id: 'thread_3',
      title: 'Filtro de Aire y Combustible Prado 2021',
      requestType: ServiceType.spareParts,
      unreadCount: 0,
      conversationCount: 0, // No quotes yet, open for stores to bid
      lastActivityAt: DateTime.now().subtract(const Duration(hours: 4)),
      clientName: 'Carlos Gómez (Mecánico)',
      clientId: 'client_carlos',
      fotoUrl: 'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?auto=format&fit=crop&w=500&q=80',
    ),
  ];

  static final List<ChatConversationModel> _conversations = [
    // Conversations for thread_1
    ChatConversationModel(
      id: 'conv_1_1',
      threadId: 'thread_1',
      participantName: 'Repuestos El Amigo',
      participantAvatarUrl: null,
      lastMessage: 'Sí, lo tenemos en stock para entrega inmediata. ¿Le sirve?',
      unreadCount: 1,
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 5)),
      hasQuote: true,
      isFixedPrice: true,
      price: 3200,
    ),
    ChatConversationModel(
      id: 'conv_1_2',
      threadId: 'thread_1',
      participantName: 'Distribuidora Automotriz H',
      participantAvatarUrl: null,
      lastMessage: 'Estimado, el precio anda entre 2900 y 3500 dependiendo de la marca.',
      unreadCount: 1,
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 15)),
      hasQuote: true,
      isFixedPrice: false,
      minPrice: 2900,
      maxPrice: 3500,
    ),
    ChatConversationModel(
      id: 'conv_1_3',
      threadId: 'thread_1',
      participantName: 'Japan Parts HN',
      participantAvatarUrl: null,
      lastMessage: 'Buenas, el kit original le sale en \$4500.',
      unreadCount: 0,
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 1)),
      hasQuote: true,
      isFixedPrice: true,
      price: 4500,
    ),

    // Conversations for thread_2
    ChatConversationModel(
      id: 'conv_2_1',
      threadId: 'thread_2',
      participantName: 'Frenos y Más',
      participantAvatarUrl: null,
      lastMessage: 'Listo, te esperamos por la tarde.',
      unreadCount: 0,
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 2)),
      hasQuote: true,
      isFixedPrice: true,
      price: 850,
    ),
  ];

  static final List<ChatMessageModel> _messages = [
    // Messages for conv_1_1
    ChatMessageModel(
      id: 'msg_1',
      conversationId: 'conv_1_1',
      senderId: 'client_juan',
      senderName: 'Juan Pérez',
      isFromMe: false, // For store: true, For client: false (We'll adjust dynamically based on viewer role)
      content: 'Hola, busco el kit de embrague para Hilux 2018 motor 2.4.',
      sentAt: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
    ChatMessageModel(
      id: 'msg_2',
      conversationId: 'conv_1_1',
      senderId: 'store_amigo',
      senderName: 'Repuestos El Amigo',
      isFromMe: true,
      content: 'Hola amigo. Sí lo tenemos. El kit de embrague completo marca LUK le queda en \$3200.',
      sentAt: DateTime.now().subtract(const Duration(minutes: 15)),
      type: MessageType.offer,
    ),
    ChatMessageModel(
      id: 'msg_3',
      conversationId: 'conv_1_1',
      senderId: 'client_juan',
      senderName: 'Juan Pérez',
      isFromMe: false,
      content: '¿Incluye collarín?',
      sentAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    ChatMessageModel(
      id: 'msg_4',
      conversationId: 'conv_1_1',
      senderId: 'store_amigo',
      senderName: 'Repuestos El Amigo',
      isFromMe: true,
      content: 'Sí, lo tenemos en stock para entrega inmediata con el collarín incluido. ¿Le sirve?',
      sentAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),

    // Messages for conv_1_2
    ChatMessageModel(
      id: 'msg_5',
      conversationId: 'conv_1_2',
      senderId: 'client_juan',
      senderName: 'Juan Pérez',
      isFromMe: false,
      content: 'Cotización Hilux 2018.',
      sentAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    ChatMessageModel(
      id: 'msg_6',
      conversationId: 'conv_1_2',
      senderId: 'store_h',
      senderName: 'Distribuidora Automotriz H',
      isFromMe: true,
      content: 'Estimado, el precio anda entre 2900 y 3500 dependiendo de la marca.',
      sentAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),

    // Messages for conv_2_1
    ChatMessageModel(
      id: 'msg_7',
      conversationId: 'conv_2_1',
      senderId: 'client_maria',
      senderName: 'María Rodríguez',
      isFromMe: false,
      content: 'Buenas, ¿tienen pastillas para Corolla 2015?',
      sentAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    ChatMessageModel(
      id: 'msg_8',
      conversationId: 'conv_2_1',
      senderId: 'store_frenos',
      senderName: 'Frenos y Más',
      isFromMe: true,
      content: 'Hola María, sí tenemos marca Bosch a \$850.',
      sentAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ChatMessageModel(
      id: 'msg_9',
      conversationId: 'conv_2_1',
      senderId: 'client_maria',
      senderName: 'María Rodríguez',
      isFromMe: false,
      content: 'Excelente, voy a pasar comprando hoy.',
      sentAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ChatMessageModel(
      id: 'msg_10',
      conversationId: 'conv_2_1',
      senderId: 'store_frenos',
      senderName: 'Frenos y Más',
      isFromMe: true,
      content: 'Listo, te esperamos por la tarde.',
      sentAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  Future<List<ChatThreadModel>> getChatThreads(UserRole role) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    if (role == UserRole.store) {
      // Stores see all request threads where they can respond or have already responded
      return _threads;
    } else {
      // Normal users (Consumer, Mechanic, Workshop) see their own threads
      return _threads;
    }
  }

  Future<List<ChatConversationModel>> getConversations(String threadId, UserRole role) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (role == UserRole.store) {
      // If store, they only talk to the client. So they only see 1 conversation inside a thread
      // We search if they already have an active conversation or we return/create one
      final storeConvs = _conversations.where((c) => c.threadId == threadId && c.participantName == 'Repuestos El Amigo').toList();
      return storeConvs;
    } else {
      // Requesters see all conversations (offers) from stores
      return _conversations.where((c) => c.threadId == threadId).toList();
    }
  }

  Future<List<ChatMessageModel>> getMessages(String conversationId, UserRole role) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    final rawMessages = _messages.where((m) => m.conversationId == conversationId).toList();
    
    // Dynamically adjust `isFromMe` depending on who is reading
    return rawMessages.map((m) {
      final isFromStore = m.senderId.startsWith('store_');
      final isFromMe = (role == UserRole.store) ? isFromStore : !isFromStore;
      return ChatMessageModel(
        id: m.id,
        conversationId: m.conversationId,
        senderId: m.senderId,
        senderName: m.senderName,
        isFromMe: isFromMe,
        content: m.content,
        type: m.type,
        sentAt: m.sentAt,
        isRead: m.isRead,
      );
    }).toList();
  }

  Future<ChatMessageModel> sendMessage(String conversationId, String content, UserRole role) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final isStore = role == UserRole.store;
    final newMessage = ChatMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: isStore ? 'store_amigo' : 'client_current',
      senderName: isStore ? 'Repuestos El Amigo' : 'Mi Usuario',
      isFromMe: true,
      content: content,
      sentAt: DateTime.now(),
    );

    _messages.add(newMessage);

    // Update conversation preview
    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      final old = _conversations[idx];
      _conversations[idx] = ChatConversationModel(
        id: old.id,
        threadId: old.threadId,
        participantName: old.participantName,
        participantAvatarUrl: old.participantAvatarUrl,
        lastMessage: content,
        unreadCount: 0,
        lastMessageAt: DateTime.now(),
        hasQuote: old.hasQuote,
        isFixedPrice: old.isFixedPrice,
        price: old.price,
        minPrice: old.minPrice,
        maxPrice: old.maxPrice,
      );
    }

    return newMessage;
  }

  Future<ChatConversationModel> createQuote({
    required String threadId,
    required bool isFixedPrice,
    double? price,
    double? minPrice,
    double? maxPrice,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final thread = _threads.firstWhere((t) => t.id == threadId);
    final convId = 'conv_${threadId}_store_amigo';
    
    // Create new conversation
    final newConv = ChatConversationModel(
      id: convId,
      threadId: threadId,
      participantName: 'Repuestos El Amigo', // Store name
      participantAvatarUrl: null,
      lastMessage: isFixedPrice 
          ? 'Hemos tomado su solicitud. Precio cotizado: \$${price?.toStringAsFixed(0)}' 
          : 'Hemos tomado su solicitud. Precio estimado: \$${minPrice?.toStringAsFixed(0)} - \$${maxPrice?.toStringAsFixed(0)}',
      unreadCount: 0,
      lastMessageAt: DateTime.now(),
      hasQuote: true,
      isFixedPrice: isFixedPrice,
      price: price,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );

    // Remove old if any
    _conversations.removeWhere((c) => c.id == convId);
    _conversations.add(newConv);

    // Increment thread's conversation count and update activity
    final tIdx = _threads.indexWhere((t) => t.id == threadId);
    if (tIdx != -1) {
      final oldThread = _threads[tIdx];
      _threads[tIdx] = ChatThreadModel(
        id: oldThread.id,
        title: oldThread.title,
        requestType: oldThread.requestType,
        unreadCount: oldThread.unreadCount,
        conversationCount: oldThread.conversationCount + 1,
        lastActivityAt: DateTime.now(),
        isOpen: oldThread.isOpen,
        clientName: oldThread.clientName,
        clientId: oldThread.clientId,
      );
    }

    // Add first auto-message with offer
    final priceStr = isFixedPrice 
        ? '\$${price?.toStringAsFixed(0)} (Fijo)' 
        : '\$${minPrice?.toStringAsFixed(0)} - \$${maxPrice?.toStringAsFixed(0)} (Rango)';
    
    _messages.add(ChatMessageModel(
      id: 'msg_quote_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: convId,
      senderId: 'store_amigo',
      senderName: 'Repuestos El Amigo',
      isFromMe: true,
      content: '¡Hola! Hemos cotizado tu repuesto por un valor de $priceStr.',
      type: MessageType.offer,
      sentAt: DateTime.now(),
    ));

    return newConv;
  }
}
