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

  bool? _lastMessageIsFromMe(Map<String, dynamic> json) {
    final explicit = json['lastMessageIsFromMe'];
    if (explicit is bool) return explicit;

    final senderId =
        (json['lastMessageSenderId'] ?? json['lastMessageSender']?['id'])
            ?.toString();
    if (senderId == null || senderId.isEmpty) return null;
    return senderId == getCurrentUserId();
  }

  Future<ChatThreadsResult> getChatThreads(
    UserRole role, {
    String? statusFilter,
    int page = 1,
    int pageSize = 20,
  }) async {
    final isStore = role == UserRole.store;
    var endpoint =
        isStore ? ApiEndpoints.storeSearchRequests : ApiEndpoints.searchMe;
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
          conversationCount: json['totalOffersCount'] as int? ??
              (json['hasOffer'] == true ? 1 : 0),
          lastActivityAt: DateTime.parse(
            (json['lastMessageAt'] ?? json['createdAt']).toString(),
          ),
          isOpen: json['requestStatus'] != 'CLOSED',
          clientName: json['consumerName'] as String? ?? 'Cliente',
          clientId: null,
          fotoUrl: json['photoUrl'] as String?,
          details: json['details'] as String?,
          partType: json['partType'] as String?,
          vehicleYear: json['vehicle']?['year'] as int?,
          subcategory: subcategoryName as String?,
          expiresAt: json['expiresAt'] != null
              ? DateTime.tryParse(json['expiresAt'].toString())
              : null,
          isExpired: json['isExpired'] as bool? ?? false,
          totalOffersCount: json['totalOffersCount'] as int? ?? 0,
          consumerAvatar: json['consumerAvatar'] as String?,
          distance: json['distancia'] != null
              ? double.tryParse(json['distancia'].toString())
              : null,
          hasOffer: json['hasOffer'] as bool? ?? false,
          offerId: json['offerId'] as String?,
          offerStatus: json['offerStatus'] as String?,
          offerPrice: json['offerPrice'] != null
              ? double.tryParse(json['offerPrice'].toString())
              : null,
          deliveryCost: json['deliveryCost'] != null
              ? double.tryParse(json['deliveryCost'].toString())
              : null,
          totalCost: json['totalCost'] != null
              ? double.tryParse(json['totalCost'].toString())
              : null,
          lastMessage: json['lastMessage'] as String?,
          conversationId: json['conversationId'] as String?,
          searchMatchId: json['searchMatchId'] as String?,
          matchState: json['matchState'] as String?,
          declinedAt: json['declinedAt'] != null
              ? DateTime.tryParse(json['declinedAt'].toString())
              : null,
          declineReason: json['declineReason'] as String?,
          isInquiry: json['isInquiry'] as bool? ?? false,
          cancelledAt: json['cancelledAt'] != null
              ? DateTime.tryParse(json['cancelledAt'].toString())
              : null,
          cancelSource: json['cancelSource'] as String?,
          cancelReason: json['cancelReason'] as String?,
        );
      } else {
        final variant = json['userCar']?['variant'];
        final model = variant?['model'];
        final brandName = model?['brand']?['name'] ?? '';
        final modelName = model?['name'] ?? '';
        final title = '$brandName $modelName'.trim();
        final subcategoryName = json['subcategory']?['name'];

        return ChatThreadModel(
          id: json['id'] as String,
          title: title.isEmpty
              ? (subcategoryName ?? 'Vehículo no especificado')
              : title,
          requestType: ServiceType.spareParts,
          unreadCount: json['unreadCount'] as int? ??
              json['_count']?['offers'] as int? ??
              0,
          conversationCount: json['totalOffersCount'] as int? ??
              json['_count']?['offers'] as int? ??
              0,
          lastActivityAt: DateTime.parse(json['createdAt'] as String),
          isOpen: json['status'] == 'OPEN',
          clientName: null,
          clientId: json['consumerId'] as String?,
          fotoUrl: json['photoUrl'] as String?,
          details: json['details'] as String?,
          partType: json['partType'] as String?,
          vehicleYear: variant?['year'] as int?,
          subcategory: subcategoryName as String?,
          expiresAt: json['expiresAt'] != null
              ? DateTime.tryParse(json['expiresAt'].toString())
              : null,
          isExpired: json['isExpired'] as bool? ?? false,
          totalOffersCount: json['totalOffersCount'] as int? ??
              json['_count']?['offers'] as int? ??
              0,
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
    if (role == UserRole.store) {
      // A store never receives competing offers for a request. The previous
      // implementation downloaded the whole sales inbox and discarded it.
      return const [];
    }

    // Consumer side
    final response = await _dioClient.get(ApiEndpoints.searchOffers(threadId));
    final data = response.data as List;

    return data.map((json) {
      final store = json['store'] as Map<String, dynamic>?;
      return ChatConversationModel(
        id: json['id'],
        conversationId: json['conversationId'] as String?,
        threadId: threadId,
        participantName: store?['name'] ?? 'Tienda',
        participantAvatarUrl: store?['logoUrl'] as String?,
        lastMessage: (json['lastMessage'] ?? json['message'] ?? '').toString(),
        lastMessageIsFromMe: _lastMessageIsFromMe(json),
        unreadCount: json['unreadCount'] as int? ?? 0,
        lastMessageAt: DateTime.parse(
          (json['lastMessageAt'] ?? json['createdAt']).toString(),
        ),
        offerId: json['id'],
        offerStatus: json['status'],
        searchMatchId: json['searchMatchId'] as String?,
        declinedAt: json['declinedAt'] != null
            ? DateTime.tryParse(json['declinedAt'].toString())
            : null,
        declineReason: json['declineReason'] as String?,
        cancelledAt: json['cancelledAt'] != null
            ? DateTime.tryParse(json['cancelledAt'].toString())
            : null,
        cancelSource: json['cancelSource'] as String?,
        cancelReason: json['cancelReason'] as String?,
        hasQuote: true,
        isInquiry: json['status'] == 'INQUIRY',
        price: json['price'] != null
            ? double.tryParse(json['price'].toString())
            : null,
        deliveryCost: json['deliveryCost'] != null
            ? double.tryParse(json['deliveryCost'].toString())
            : null,
        totalCost: json['totalCost'] != null
            ? double.tryParse(json['totalCost'].toString())
            : null,
        spareBrand: json['spareBrand'],
        sparePhotoUrl: json['sparePhotoUrl'],
        // Señales de confianza reales de la tienda (enriquecidas por el API)
        storeLogoUrl: store?['logoUrl'] as String?,
        verified: store?['verified'] as bool? ?? false,
        hasDelivery: store?['hasDelivery'] as bool? ?? false,
        distanceKm: (store?['distance'] as num?)?.toDouble(),
        storeRating: (store?['rating'] as num?)?.toDouble(),
        storeReviewCount: (store?['ratingCount'] as num?)?.toInt() ?? 0,
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

  /// Recupera sólo el mensaje más reciente para completar previews cuya
  /// respuesta de bandeja todavía no incluye la autoría.
  Future<ChatMessageModel?> getLatestMessage(String conversationId) async {
    final response =
        await _dioClient.get('conversations/$conversationId/messages?limit=1');
    final data = response.data as List;
    if (data.isEmpty) return null;

    return ChatMessageModel.fromJson(
      Map<String, dynamic>.from(data.first as Map),
      getCurrentUserId(),
    );
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
    final currentUserId = getCurrentUserId();
    return data
        .map(
          (json) => ChatConversationModel.fromJson(
            Map<String, dynamic>.from(json as Map),
            currentUserId: currentUserId,
          ),
        )
        .toList();
  }

  Future<ChatConversationModel> getConversationDetails(
      String conversationId) async {
    final response = await _dioClient.get('conversations/$conversationId');
    final json = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : response.data as Map<String, dynamic>;
    return ChatConversationModel.fromJson(
      json,
      currentUserId: getCurrentUserId(),
    );
  }

  Future<void> markAsRead(String conversationId) async {
    await _dioClient.patch('conversations/$conversationId/read');
  }

  /// Crea la oferta para la solicitud. Sin [price] abre una consulta
  /// (INQUIRY): el backend crea la conversación de inmediato y la tienda
  /// puede chatear antes de cotizar.
  Future<ChatConversationModel> createQuote({
    required String threadId,
    String? searchMatchId,
    double? price,
    double? deliveryCost,
    String? brand,
    String? photoPath,
  }) async {
    // Normal navigation already owns this id. The inbox lookup remains only
    // as a compatibility fallback for old deep links and stale local state.
    var resolvedSearchMatchId = searchMatchId;
    if (resolvedSearchMatchId == null || resolvedSearchMatchId.isEmpty) {
      // A stale/deep-link request may no longer be in the default PENDING
      // page. Keep this compatibility lookup bounded while covering all
      // statuses and a substantially larger window.
      const fallbackEndpoint =
          '${ApiEndpoints.storeSearchRequests}?status=ALL&page=1&pageSize=100';
      final reqsRes = await _dioClient.get(fallbackEndpoint);
      final rawReqs = reqsRes.data;
      final List reqs = rawReqs is Map && rawReqs.containsKey('items')
          ? (rawReqs['items'] as List)
          : (rawReqs is List ? rawReqs : []);
      Map<String, dynamic>? match;
      for (final rawRequest in reqs) {
        if (rawRequest is! Map || rawRequest['id'] != threadId) continue;
        match = Map<String, dynamic>.from(rawRequest);
        break;
      }
      resolvedSearchMatchId = match?['searchMatchId']?.toString();
    }
    if (resolvedSearchMatchId == null || resolvedSearchMatchId.isEmpty) {
      throw Exception('SearchMatch not found for this request');
    }

    String? sparePhotoUrl = photoPath;
    if (photoPath != null &&
        photoPath.isNotEmpty &&
        !photoPath.startsWith('http://') &&
        !photoPath.startsWith('https://')) {
      sparePhotoUrl = await _dioClient.uploadOfferImage(photoPath);
    }

    final payload = {
      'searchMatchId': resolvedSearchMatchId,
      if (price != null) 'price': price,
      if (deliveryCost != null) 'deliveryCost': deliveryCost,
      if (brand != null && brand.isNotEmpty) 'spareBrand': brand,
      if (sparePhotoUrl != null && sparePhotoUrl.isNotEmpty)
        'sparePhotoUrl': sparePhotoUrl,
    };

    final response = await _dioClient.post('offers', data: payload);
    final json = response.data;
    final offerId = json['id'];

    // Una INQUIRY ya trae conversationId (creada atómicamente en el backend).
    // Para ofertas con precio, se crea/recupera vía from-offer.
    String? realConversationId = json['conversationId'] as String?;
    if (realConversationId == null) {
      final convRes = await _dioClient
          .post('conversations/from-offer', data: {'offerId': offerId});
      realConversationId = convRes.data['id'] as String;
    }

    return ChatConversationModel(
      id: realConversationId,
      threadId: threadId,
      participantName: 'Mi Tienda',
      lastMessage: json['message'] ?? '',
      unreadCount: 0,
      lastMessageAt: DateTime.parse(json['createdAt']),
      offerId: offerId,
      offerStatus: json['status'],
      searchMatchId: resolvedSearchMatchId,
      hasQuote: true,
      isInquiry: json['status'] == 'INQUIRY',
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      deliveryCost: json['deliveryCost'] != null
          ? double.tryParse(json['deliveryCost'].toString())
          : null,
      totalCost: json['totalCost'] != null
          ? double.tryParse(json['totalCost'].toString())
          : null,
      spareBrand: json['spareBrand'],
      sparePhotoUrl: json['sparePhotoUrl'],
    );
  }

  /// Cotiza (o re-cotiza) una oferta existente desde el chat.
  /// PATCH /offers/:id — con precio sobre una INQUIRY la promueve a SENT.
  Future<void> quoteOffer({
    required String offerId,
    required double price,
    required bool updateDeliveryCost,
    double? deliveryCost,
    String? brand,
    String? photoPath,
  }) async {
    String? sparePhotoUrl = photoPath;
    if (photoPath != null &&
        photoPath.isNotEmpty &&
        !photoPath.startsWith('http://') &&
        !photoPath.startsWith('https://')) {
      sparePhotoUrl = await _dioClient.uploadOfferImage(photoPath);
    }

    await _dioClient.patch('offers/$offerId', data: {
      'price': price,
      if (updateDeliveryCost) 'deliveryCost': deliveryCost,
      if (brand != null && brand.isNotEmpty) 'spareBrand': brand,
      if (sparePhotoUrl != null && sparePhotoUrl.isNotEmpty)
        'sparePhotoUrl': sparePhotoUrl,
    });
  }

  Future<void> buyOffer(String offerId) async {
    await _dioClient.post('offers/$offerId/buy');
  }

  Future<void> deliverOffer(String offerId) async {
    await _dioClient.post('offers/$offerId/deliver');
  }

  Future<void> cancelOffer(String offerId, {String? reason}) async {
    await _dioClient.post(
      ApiEndpoints.offerCancel(offerId),
      data: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
  }

  Future<void> declineMatch(String searchMatchId, String reason) async {
    await _dioClient.post(
      ApiEndpoints.storeSearchRequestDecline(searchMatchId),
      data: {'reason': reason},
    );
  }

  Future<void> undoDecline(String searchMatchId) async {
    await _dioClient.delete(
      ApiEndpoints.storeSearchRequestDecline(searchMatchId),
    );
  }
}
