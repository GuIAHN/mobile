import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/chat_thread_model.dart';
import '../models/chat_conversation_model.dart';
import '../models/chat_message_model.dart';
import '../../domain/entities/chat_message.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../../../../core/domain/enums/user_role.dart';

class ChatRemoteDataSource {
  final DioClient _dioClient;
  final String Function() getCurrentUserId;

  ChatRemoteDataSource(this._dioClient, this.getCurrentUserId);

  Future<List<ChatThreadModel>> getChatThreads(UserRole role) async {
    final isStore = role == UserRole.store;
    final endpoint = isStore ? ApiEndpoints.storeSearchRequests : ApiEndpoints.searchMe;

    final response = await _dioClient.get(endpoint);
    final data = response.data as List;

    return data.map((json) {
      if (isStore) {
        final brandName = json['vehicle']?['brand'] ?? '';
        final modelName = json['vehicle']?['model'] ?? '';
        final title = '$brandName $modelName'.trim();
        final subcategoryName = json['subcategory']?['name'];
        
        return ChatThreadModel(
          id: json['id'],
          title: title.isEmpty ? (subcategoryName ?? 'Solicitud') : title,
          requestType: ServiceType.spareParts,
          unreadCount: 0,
          conversationCount: 0,
          lastActivityAt: DateTime.parse(json['createdAt']),
          isOpen: true,
          clientName: 'Cliente Anónimo',
          clientId: null,
          fotoUrl: json['photoUrl'],
          details: json['details'],
          partType: json['partType'],
          vehicleYear: json['vehicle']?['year'],
          subcategory: subcategoryName,
        );
      } else {
        final model = json['userCar']?['model'];
        final brandName = model?['brand']?['name'] ?? '';
        final modelName = model?['name'] ?? '';
        final title = '$brandName $modelName'.trim();
        final subcategoryName = json['subcategory']?['name'];
        
        return ChatThreadModel(
          id: json['id'],
          title: title.isEmpty ? (subcategoryName ?? 'Solicitud') : title,
          requestType: ServiceType.spareParts,
          unreadCount: json['_count']?['offers'] ?? 0,
          conversationCount: json['_count']?['offers'] ?? 0,
          lastActivityAt: DateTime.parse(json['createdAt']),
          isOpen: json['status'] == 'OPEN',
          clientName: null,
          clientId: json['consumerId'],
          fotoUrl: json['photoUrl'],
          details: json['details'],
          partType: json['partType'],
          vehicleYear: model?['year'],
          subcategory: subcategoryName,
        );
      }
    }).toList();
  }

  Future<List<ChatConversationModel>> getConversations(String threadId, UserRole role) async {
    // For a store, they shouldn't query search offers endpoint because they don't see others' offers
    // But our API allows consumer to get offers. Let's see how Store sees its own offer.
    // If it's consumer, get all offers for the search request.
    // If it's a store, they only have 1 conversation per search Match.
    if (role == UserRole.store) {
      // Get the visible requests to find the searchMatchId
      final reqsRes = await _dioClient.get(ApiEndpoints.storeSearchRequests);
      final reqs = reqsRes.data as List;
      final match = reqs.firstWhere((r) => r['id'] == threadId, orElse: () => null);
      if (match != null && match['searchMatchId'] != null) {
        // Return a dummy conversation representing the chat with the client
        // To be accurate we should fetch if they already made an offer, but for now we just return an empty list 
        // or a single local conversation object.
        return [];
      }
      return [];
    }

    // Consumer side
    final response = await _dioClient.get(ApiEndpoints.searchOffers(threadId));
    final data = response.data as List;

    return data.map((json) {
      return ChatConversationModel(
        id: json['id'],
        threadId: threadId,
        participantName: json['store']?['name'] ?? 'Tienda',
        participantAvatarUrl: null,
        lastMessage: json['message'] ?? '',
        unreadCount: 0,
        lastMessageAt: DateTime.parse(json['createdAt']),
        hasQuote: true,
        isFixedPrice: true,
        price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
        spareBrand: json['spareBrand'],
        sparePhotoUrl: json['sparePhotoUrl'],
      );
    }).toList();
  }

  Future<List<ChatMessageModel>> getMessages(String conversationId, UserRole role) async {
    final response = await _dioClient.get('conversations/$conversationId/messages');
    final data = response.data as List;
    final currentUserId = getCurrentUserId();
    return data.map((json) => ChatMessageModel.fromJson(json, currentUserId)).toList();
  }

  Future<ChatMessageModel> sendMessage(String conversationId, String content, UserRole role) async {
    // Handled by sockets now
    throw UnimplementedError();
  }

  Future<String> startChatFromOffer(String offerId) async {
    final response = await _dioClient.post('conversations/from-offer', data: {'offerId': offerId});
    return response.data['id'];
  }

  Future<List<ChatConversationModel>> getMyConversations() async {
    final response = await _dioClient.get('conversations/me');
    final data = response.data as List;
    return data.map((json) {
      return ChatConversationModel(
        id: json['id'],
        threadId: json['offerId'] ?? 'DIRECT', // Fallback for direct chats
        participantName: json['participantName'],
        participantAvatarUrl: json['participantAvatarUrl'],
        lastMessage: '', // Messages are inside the conversation
        unreadCount: json['unreadCount'] ?? 0,
        lastMessageAt: json['lastMessageAt'] != null ? DateTime.parse(json['lastMessageAt']) : DateTime.now(),
        hasQuote: json['hasQuote'] ?? false,
        isFixedPrice: json['isFixedPrice'] ?? false,
        price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
        spareBrand: json['spareBrand'],
        sparePhotoUrl: json['sparePhotoUrl'],
      );
    }).toList();
  }

  Future<ChatConversationModel> getConversationDetails(String conversationId) async {
    final response = await _dioClient.get('conversations/$conversationId');
    final json = response.data;
    return ChatConversationModel(
      id: json['id'],
      threadId: json['offerId'] ?? 'DIRECT',
      participantName: json['participantName'],
      participantAvatarUrl: json['participantAvatarUrl'],
      lastMessage: '',
      unreadCount: json['unreadCount'] ?? 0,
      lastMessageAt: json['lastMessageAt'] != null ? DateTime.parse(json['lastMessageAt']) : DateTime.now(),
      hasQuote: json['hasQuote'] ?? false,
      isFixedPrice: json['isFixedPrice'] ?? false,
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
      spareBrand: json['spareBrand'],
      sparePhotoUrl: json['sparePhotoUrl'],
    );
  }

  Future<ChatConversationModel> createQuote({
    required String threadId,
    required bool isFixedPrice,
    double? price,
    double? minPrice,
    double? maxPrice,
    String? brand,
    String? photoPath,
  }) async {
    // Store sends an offer to a SearchMatch
    // 1. Get searchMatchId by listing requests
    final reqsRes = await _dioClient.get(ApiEndpoints.storeSearchRequests);
    final reqs = reqsRes.data as List;
    final match = reqs.firstWhere((r) => r['id'] == threadId, orElse: () => null);
    
    if (match == null || match['searchMatchId'] == null) {
      throw Exception('SearchMatch not found for this request');
    }

    final searchMatchId = match['searchMatchId'];
    
    final String? mockFotoUrl = photoPath != null 
        ? 'https://guiautomotriz.com/uploads/temp_${DateTime.now().millisecondsSinceEpoch}.jpg' 
        : null;

    final payload = {
      'searchMatchId': searchMatchId,
      'price': isFixedPrice ? price : minPrice,
      'message': 'Nueva oferta enviada',
      if (brand != null && brand.isNotEmpty) 'spareBrand': brand,
      if (mockFotoUrl != null) 'sparePhotoUrl': mockFotoUrl,
    };

    final response = await _dioClient.post('offers', data: payload);
    final json = response.data;

    return ChatConversationModel(
      id: json['id'],
      threadId: threadId,
      participantName: 'Mi Tienda',
      lastMessage: json['message'],
      unreadCount: 0,
      lastMessageAt: DateTime.parse(json['createdAt']),
      hasQuote: true,
      isFixedPrice: true,
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
      spareBrand: json['spareBrand'],
      sparePhotoUrl: json['sparePhotoUrl'],
    );
  }
}
