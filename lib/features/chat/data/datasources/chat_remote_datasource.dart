import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/chat_thread_model.dart';
import '../models/chat_conversation_model.dart';
import '../models/chat_message_model.dart';
import '../../domain/entities/chat_threads_result.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../../../../core/domain/enums/user_role.dart';

class ChatRemoteDataSource {
  final DioClient _dioClient;
  final String Function() getCurrentUserId;

  ChatRemoteDataSource(this._dioClient, this.getCurrentUserId);

  Future<ChatThreadsResult> getChatThreads(
    UserRole role, {
    String? statusFilter,
    int page = 1,
    int pageSize = 20,
  }) async {
    final isStore = role == UserRole.store;
    var endpoint = isStore ? ApiEndpoints.storeSearchRequests : ApiEndpoints.searchMe;
    if (statusFilter != null && statusFilter.isNotEmpty) {
      endpoint = '$endpoint?status=$statusFilter&page=$page&pageSize=$pageSize';
    } else {
      endpoint = '$endpoint?page=$page&pageSize=$pageSize';
    }

    final response = await _dioClient.get(endpoint);
    final rawData = response.data;
    final List dataList;
    Map<String, int> counts = {};
    int total = 0;

    if (rawData is Map && rawData.containsKey('items')) {
      dataList = rawData['items'] as List;
      total = rawData['total'] as int? ?? 0;
      if (rawData['counts'] is Map) {
        final rawCounts = rawData['counts'] as Map<String, dynamic>;
        counts = rawCounts.map((k, v) => MapEntry(k, (v as num).toInt()));
      }
    } else if (rawData is List) {
      dataList = rawData;
    } else {
      dataList = [];
    }

    final threads = dataList.map((jsonMap) {
      final json = jsonMap as Map<String, dynamic>;
      if (isStore) {
        final brandName = json['vehicle']?['brand'] ?? '';
        final modelName = json['vehicle']?['model'] ?? '';
        final title = '$brandName $modelName'.trim();
        final subcategoryName = json['subcategory']?['name'];

        return ChatThreadModel(
          id: json['id'] as String,
          title: title.isEmpty ? (subcategoryName ?? 'Solicitud') : title,
          requestType: ServiceType.spareParts,
          unreadCount: json['unreadCount'] as int? ?? 0,
          conversationCount: json['totalOffersCount'] as int? ?? (json['hasOffer'] == true ? 1 : 0),
          lastActivityAt: DateTime.parse(json['createdAt'] as String),
          isOpen: json['requestStatus'] != 'CLOSED',
          clientName: json['consumerName'] as String? ?? 'Cliente',
          clientId: null,
          fotoUrl: json['photoUrl'] as String?,
          details: json['details'] as String?,
          partType: json['partType'] as String?,
          vehicleYear: json['vehicle']?['year'] as int?,
          subcategory: subcategoryName as String?,
          expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt'].toString()) : null,
          isExpired: json['isExpired'] as bool? ?? false,
          totalOffersCount: json['totalOffersCount'] as int? ?? 0,
          consumerAvatar: json['consumerAvatar'] as String?,
          distance: json['distancia'] != null ? double.tryParse(json['distancia'].toString()) : null,
          hasOffer: json['hasOffer'] as bool? ?? false,
          offerId: json['offerId'] as String?,
          offerStatus: json['offerStatus'] as String?,
          offerPrice: json['offerPrice'] != null
              ? double.tryParse(json['offerPrice'].toString())
              : null,
          lastMessage: json['lastMessage'] as String?,
          conversationId: json['conversationId'] as String?,
        );
      } else {
        final model = json['userCar']?['model'];
        final brandName = model?['brand']?['name'] ?? '';
        final modelName = model?['name'] ?? '';
        final title = '$brandName $modelName'.trim();
        final subcategoryName = json['subcategory']?['name'];

        return ChatThreadModel(
          id: json['id'] as String,
          title: title.isEmpty ? (subcategoryName ?? 'Vehículo no especificado') : title,
          requestType: ServiceType.spareParts,
          unreadCount: json['unreadCount'] as int? ?? json['_count']?['offers'] as int? ?? 0,
          conversationCount: json['totalOffersCount'] as int? ?? json['_count']?['offers'] as int? ?? 0,
          lastActivityAt: DateTime.parse(json['createdAt'] as String),
          isOpen: json['status'] == 'OPEN',
          clientName: null,
          clientId: json['consumerId'] as String?,
          fotoUrl: json['photoUrl'] as String?,
          details: json['details'] as String?,
          partType: json['partType'] as String?,
          vehicleYear: model?['year'] as int?,
          subcategory: subcategoryName as String?,
          expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt'].toString()) : null,
          isExpired: json['isExpired'] as bool? ?? false,
          totalOffersCount: json['totalOffersCount'] as int? ?? json['_count']?['offers'] as int? ?? 0,
          bestOfferPrice: json['bestOfferPrice'] != null
              ? double.tryParse(json['bestOfferPrice'].toString())
              : null,
          bestOfferStoreName: json['bestOfferStoreName'] as String?,
          bestOfferStatus: json['bestOfferStatus'] as String?,
        );
      }
    }).toList();

    return ChatThreadsResult(
      threads: threads,
      counts: counts,
      total: total,
    );
  }

  Future<List<ChatConversationModel>> getConversations(
      String threadId, UserRole role) async {
    // For a store, they shouldn't query search offers endpoint because they don't see others' offers
    // But our API allows consumer to get offers. Let's see how Store sees its own offer.
    // If it's consumer, get all offers for the search request.
    // If it's a store, they only have 1 conversation per search Match.
    if (role == UserRole.store) {
      // Get the visible requests to find the searchMatchId
      final reqsRes = await _dioClient.get(ApiEndpoints.storeSearchRequests);
      final rawReqs = reqsRes.data;
      final List reqs = rawReqs is Map && rawReqs.containsKey('items')
          ? (rawReqs['items'] as List)
          : (rawReqs is List ? rawReqs : []);
      final match =
          reqs.firstWhere((r) => r['id'] == threadId, orElse: () => null);
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
      final store = json['store'] as Map<String, dynamic>?;
      return ChatConversationModel(
        id: json['id'],
        threadId: threadId,
        participantName: store?['name'] ?? 'Tienda',
        participantAvatarUrl: store?['logoUrl'] as String?,
        lastMessage: json['message'] ?? '',
        unreadCount: json['unreadCount'] as int? ?? 0,
        lastMessageAt: DateTime.parse(json['createdAt']),
        offerId: json['id'],
        offerStatus: json['status'],
        hasQuote: true,
        isFixedPrice: true,
        price: json['price'] != null
            ? double.tryParse(json['price'].toString())
            : null,
        spareBrand: json['spareBrand'],
        sparePhotoUrl: json['sparePhotoUrl'],
        // Señales de confianza reales de la tienda (enriquecidas por el API)
        storeLogoUrl: store?['logoUrl'] as String?,
        verified: store?['verified'] as bool? ?? false,
        hasDelivery: store?['hasDelivery'] as bool? ?? false,
        distanceKm: (store?['distance'] as num?)?.toDouble(),
        note: json['message'] as String?,
        hasConversation: json['has_conversation'] as bool? ?? false,
      );
    }).toList();
  }

  Future<List<ChatMessageModel>> getMessages(
      String conversationId, UserRole role) async {
    final response =
        await _dioClient.get('conversations/$conversationId/messages');
    final data = response.data as List;
    final currentUserId = getCurrentUserId();
    return data
        .map((json) => ChatMessageModel.fromJson(json, currentUserId))
        .toList();
  }

  Future<ChatMessageModel> sendMessage(
      String conversationId, String content, UserRole role) async {
    // Handled by sockets now
    throw UnimplementedError();
  }

  Future<String> startChatFromOffer(String offerId) async {
    final response = await _dioClient
        .post('conversations/from-offer', data: {'offerId': offerId});
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
        lastMessage: json['lastMessage'] ?? '',
        unreadCount: json['unreadCount'] ?? 0,
        lastMessageAt: json['lastMessageAt'] != null
            ? DateTime.parse(json['lastMessageAt'])
            : DateTime.now(),
        offerId: json['offerId'],
        offerStatus: json['offerStatus'],
        hasQuote: json['hasQuote'] ?? false,
        isFixedPrice: json['isFixedPrice'] ?? false,
        price: json['price'] != null
            ? double.tryParse(json['price'].toString())
            : null,
        spareBrand: json['spareBrand'],
        sparePhotoUrl: json['sparePhotoUrl'],
        note: json['note'] as String?,
      );
    }).toList();
  }

  Future<ChatConversationModel> getConversationDetails(
      String conversationId) async {
    final response = await _dioClient.get('conversations/$conversationId');
    final json = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : response.data as Map<String, dynamic>;
    return ChatConversationModel(
      id: json['id'],
      threadId: json['offerId'] ?? 'DIRECT',
      participantName: json['participantName'],
      participantAvatarUrl: json['participantAvatarUrl'],
      lastMessage: json['lastMessage'] ?? '',
      unreadCount: json['unreadCount'] ?? 0,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'])
          : DateTime.now(),
      offerId: json['offerId'],
      offerStatus: json['offerStatus'],
      hasQuote: json['hasQuote'] ?? false,
      isFixedPrice: json['isFixedPrice'] ?? false,
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      spareBrand: json['spareBrand'],
      sparePhotoUrl: json['sparePhotoUrl'],
      hasDelivery: json['hasDelivery'] as bool? ?? false,
      storeUserId: json['storeUserId'] as String?,
      hasReviewed: json['hasReviewed'] as bool? ?? false,
      reviewRating: (json['reviewRating'] as num?)?.toInt(),
      reviewComment: json['reviewComment'] as String?,
      vehicleTitle: json['vehicleTitle'] as String?,
      subcategoryName: json['subcategoryName'] as String?,
      partType: json['partType'] as String?,
      requestDetails: json['requestDetails'] as String?,
      offerMessage: json['offerMessage'] as String?,
    );
  }

  Future<void> markAsRead(String conversationId) async {
    await _dioClient.patch('conversations/$conversationId/read');
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
    final rawReqs = reqsRes.data;
    final List reqs = rawReqs is Map && rawReqs.containsKey('items')
        ? (rawReqs['items'] as List)
        : (rawReqs is List ? rawReqs : []);
    final match =
        reqs.firstWhere((r) => r['id'] == threadId, orElse: () => null);

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
    final offerId = json['id'];

    // Automatically create or fetch conversation for this offer
    final convRes = await _dioClient
        .post('conversations/from-offer', data: {'offerId': offerId});
    final realConversationId = convRes.data['id'];

    return ChatConversationModel(
      id: realConversationId,
      threadId: threadId,
      participantName: 'Mi Tienda',
      lastMessage: json['message'],
      unreadCount: 0,
      lastMessageAt: DateTime.parse(json['createdAt']),
      offerId: offerId,
      offerStatus: json['status'],
      hasQuote: true,
      isFixedPrice: true,
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      spareBrand: json['spareBrand'],
      sparePhotoUrl: json['sparePhotoUrl'],
    );
  }

  Future<void> buyOffer(String offerId) async {
    await _dioClient.post('offers/$offerId/buy');
  }

  Future<void> deliverOffer(String offerId) async {
    await _dioClient.post('offers/$offerId/deliver');
  }
}
