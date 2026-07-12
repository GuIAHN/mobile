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

  ChatRemoteDataSource(this._dioClient);

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
          unreadCount: 0,
          conversationCount: 0,
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
      );
    }).toList();
  }

  Future<List<ChatMessageModel>> getMessages(String conversationId, UserRole role) async {
    // Currently no message history API, just offers.
    return [];
  }

  Future<ChatMessageModel> sendMessage(String conversationId, String content, UserRole role) async {
    // We mock this since there is no standard messaging in backend yet (only offers)
    throw UnimplementedError();
  }

  Future<ChatConversationModel> createQuote({
    required String threadId,
    required bool isFixedPrice,
    double? price,
    double? minPrice,
    double? maxPrice,
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
    
    final payload = {
      'searchMatchId': searchMatchId,
      'price': isFixedPrice ? price : minPrice,
      'message': 'Nueva oferta enviada'
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
    );
  }
}
