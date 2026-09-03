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

    if (rawData is Map && rawData.containsKey('items')) {
      dataList = rawData['items'] as List;
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
      final json = Map<String, dynamic>.from(jsonMap as Map);
      return isStore
          ? _storeThreadFromJson(json)
          : _consumerThreadFromJson(json);
    }).toList();

    return ChatThreadsResult(
      threads: threads,
      counts: counts,
    );
  }

  Future<ChatThreadModel> getRequestDetail(
    String requestId,
    UserRole role,
  ) async {
    final endpoint = role == UserRole.store
        ? ApiEndpoints.storeSearchRequestDetail(requestId)
        : ApiEndpoints.searchDetail(requestId);
    final response = await _dioClient.get(endpoint);
    final raw = response.data;
    if (raw is! Map) {
      throw const FormatException('Invalid request detail response');
    }
    final json = Map<String, dynamic>.from(raw);
    return role == UserRole.store
        ? _storeThreadFromJson(json)
        : _consumerThreadFromJson(json);
  }

  ChatThreadModel _storeThreadFromJson(Map<String, dynamic> json) {
    final vehicle = _asJsonMap(json['vehicle']);
    final brandName = _namedValue(vehicle?['brand']);
    final modelName = _namedValue(vehicle?['model']);
    final subcategoryName = _namedValue(json['subcategory']);
    final offer = _asJsonMap(json['myOffer']);
    final offerStatus = (json['offerStatus'] ?? offer?['status'])?.toString();
    final hasOffer = json['hasOffer'] as bool? ?? offer != null;
    final requestStatus = json['requestStatus']?.toString();

    return ChatThreadModel(
      id: json['id'].toString(),
      title: '$brandName $modelName'.trim().isEmpty
          ? (subcategoryName.isEmpty ? 'Solicitud' : subcategoryName)
          : '$brandName $modelName'.trim(),
      requestType: ServiceType.spareParts,
      unreadCount: _asInt(json['unreadCount']) ?? 0,
      conversationCount: _asInt(json['totalOffersCount']) ?? (hasOffer ? 1 : 0),
      lastActivityAt: DateTime.parse(
        (json['lastMessageAt'] ?? json['createdAt']).toString(),
      ),
      isOpen: requestStatus == null || requestStatus == 'OPEN',
      clientName: json['consumerName']?.toString() ?? 'Cliente',
      fotoUrl: json['photoUrl']?.toString(),
      details: json['details']?.toString(),
      partType: json['partType']?.toString(),
      vehicleYear: _asInt(vehicle?['year']),
      subcategory: subcategoryName.isEmpty ? null : subcategoryName,
      expiresAt: _asDateTime(json['expiresAt']),
      isExpired: json['isExpired'] as bool? ?? false,
      totalOffersCount: _asInt(json['totalOffersCount']) ?? 0,
      quotesCount: _asInt(json['quotesCount']) ?? 0,
      questionsCount: _asInt(json['questionsCount']) ?? 0,
      consumerAvatar: json['consumerAvatar']?.toString(),
      distance: _asDouble(json['distancia'] ?? json['distance']),
      hasOffer: hasOffer,
      offerId: (json['offerId'] ?? offer?['id'])?.toString(),
      offerStatus: offerStatus,
      offerPrice: _asDouble(json['offerPrice'] ?? offer?['price']),
      deliveryCost: _asDouble(json['deliveryCost'] ?? offer?['deliveryCost']),
      totalCost: _asDouble(json['totalCost'] ?? offer?['totalCost']),
      lastMessage: json['lastMessage']?.toString(),
      conversationId: json['conversationId']?.toString(),
      searchMatchId: json['searchMatchId']?.toString(),
      matchState: json['matchState']?.toString(),
      declinedAt: _asDateTime(json['declinedAt']),
      declineReason: json['declineReason']?.toString(),
      isInquiry: json['isInquiry'] as bool? ??
          offerStatus == 'INQUIRY' || json['matchState'] == 'INQUIRING',
      cancelledAt: _asDateTime(json['cancelledAt'] ?? offer?['cancelledAt']),
      cancelSource:
          (json['cancelSource'] ?? offer?['cancelSource'])?.toString(),
      cancelReason:
          (json['cancelReason'] ?? offer?['cancelReason'])?.toString(),
      cancelReasonCode:
          (json['cancelReasonCode'] ?? offer?['cancelReasonCode'])?.toString(),
    );
  }

  ChatThreadModel _consumerThreadFromJson(Map<String, dynamic> json) {
    final vehicle = _asJsonMap(json['vehicle']);
    final model = _asJsonMap(vehicle?['model']);
    final brandName = _namedValue(model?['brand']);
    final modelName = _namedValue(model);
    final subcategoryName = _namedValue(json['subcategory']);
    final count = _asInt(_asJsonMap(json['_count'])?['offers']) ?? 0;
    final purchasedOffer = _asJsonMap(json['purchasedOffer']);

    return ChatThreadModel(
      id: json['id'].toString(),
      title: '$brandName $modelName'.trim().isEmpty
          ? (subcategoryName.isEmpty
              ? 'Vehículo no especificado'
              : subcategoryName)
          : '$brandName $modelName'.trim(),
      requestType: ServiceType.spareParts,
      unreadCount: _asInt(json['unreadCount']) ?? count,
      conversationCount: _asInt(json['totalOffersCount']) ?? count,
      lastActivityAt: DateTime.parse(
        (json['lastMessageAt'] ?? json['createdAt']).toString(),
      ),
      isOpen: json['status'] == 'OPEN',
      clientId: json['consumerId']?.toString(),
      fotoUrl: json['photoUrl']?.toString(),
      details: json['details']?.toString(),
      partType: json['partType']?.toString(),
      vehicleYear: _asInt(vehicle?['year']),
      subcategory: subcategoryName.isEmpty ? null : subcategoryName,
      expiresAt: _asDateTime(json['expiresAt']),
      isExpired: json['isExpired'] as bool? ?? false,
      totalOffersCount: _asInt(json['totalOffersCount']) ?? count,
      quotesCount: _asInt(json['quotesCount']) ?? 0,
      questionsCount: _asInt(json['questionsCount']) ?? 0,
      hasOffer: purchasedOffer != null,
      offerId: purchasedOffer?['offerId']?.toString(),
      offerStatus: purchasedOffer?['status']?.toString(),
      offerPrice: _asDouble(purchasedOffer?['price']),
      deliveryCost: _asDouble(purchasedOffer?['deliveryCost']),
      totalCost: _asDouble(purchasedOffer?['totalCost']),
      conversationId: purchasedOffer?['conversationId']?.toString(),
      cancelledAt: _asDateTime(purchasedOffer?['cancelledAt']),
      cancelSource: purchasedOffer?['cancelSource']?.toString(),
      cancelReason: purchasedOffer?['cancelReason']?.toString(),
      cancelReasonCode: purchasedOffer?['cancelReasonCode']?.toString(),
      bestOfferPrice: _asDouble(json['bestOfferPrice']),
      bestOfferStoreName: json['bestOfferStoreName']?.toString(),
      bestOfferStatus: json['bestOfferStatus']?.toString(),
    );
  }

  Map<String, dynamic>? _asJsonMap(Object? value) {
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  String _namedValue(Object? value) {
    if (value is Map) return value['name']?.toString() ?? '';
    return value?.toString() ?? '';
  }

  int? _asInt(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

  double? _asDouble(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');

  DateTime? _asDateTime(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());

  Future<List<ChatConversationModel>> getConversations(
      String threadId, UserRole role) async {
    if (role == UserRole.store) {
      // A store never receives competing offers for a request. The previous
      // implementation downloaded the whole sales inbox and discarded it.
      return const [];
    }

    // Consumer side
    final response = await _dioClient.get(ApiEndpoints.searchOffers(threadId));
    final raw = response.data;
    final data = raw is Map ? (raw['items'] as List? ?? const []) : raw as List;

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
        cancelReasonCode: json['cancelReasonCode'] as String?,
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

  Future<void> cancelSaleByStore(
    String offerId, {
    required String reasonCode,
    String? note,
  }) async {
    await _dioClient.post(
      ApiEndpoints.offerCancelSale(offerId),
      data: {
        'reasonCode': reasonCode,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
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
