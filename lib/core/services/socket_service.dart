import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import '../network/token_refresh_coordinator.dart';
import '../realtime/event_names.dart';
import '../realtime/reconnect_policy.dart';
import '../storage/secure_storage.dart';

class RealtimeRequestException implements Exception {
  const RealtimeRequestException(this.code, this.message);

  final String code;
  final String message;

  factory RealtimeRequestException.fromAck(Object? ack) {
    final rawError = ack is Map ? ack['error'] : null;
    if (rawError is Map) {
      final rawCode = rawError['code'];
      final rawMessage = rawError['message'];
      return RealtimeRequestException(
        rawCode is String && rawCode.isNotEmpty ? rawCode : 'REQUEST_REJECTED',
        rawMessage is String && rawMessage.isNotEmpty
            ? rawMessage
            : 'La solicitud de chat no pudo procesarse.',
      );
    }
    if (rawError is String && rawError.isNotEmpty) {
      return RealtimeRequestException('REQUEST_REJECTED', rawError);
    }
    return const RealtimeRequestException(
      'REQUEST_REJECTED',
      'La solicitud de chat no pudo procesarse.',
    );
  }

  @override
  String toString() => message;
}

typedef RealtimeSocketFactory = io.Socket Function(
  String uri,
  Map<String, dynamic> options,
);

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService(
    ref.watch(secureStorageProvider),
    ref.watch(tokenRefreshCoordinatorProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

class SocketService {
  SocketService(
    this._secureStorage,
    this._tokenRefreshCoordinator, {
    RealtimeSocketFactory? socketFactory,
    ReconnectPolicy reconnectPolicy = const ReconnectPolicy(),
    Duration catchUpThreshold = Duration.zero,
    Duration messageAckTimeout = const Duration(seconds: 8),
  })  : _socketFactory =
            socketFactory ?? ((uri, options) => io.io(uri, options)),
        _reconnectPolicy = reconnectPolicy,
        _catchUpThreshold = catchUpThreshold,
        _messageAckTimeout = messageAckTimeout;

  final SecureStorage _secureStorage;
  final TokenRefreshCoordinator _tokenRefreshCoordinator;
  final RealtimeSocketFactory _socketFactory;
  final ReconnectPolicy _reconnectPolicy;
  final Duration _catchUpThreshold;
  final Duration _messageAckTimeout;

  io.Socket? _socket;
  String? _connectedToken;
  bool _isConnecting = false;
  bool _shouldReconnect = false;
  bool _refreshInProgress = false;
  bool _requiresRefresh = false;
  bool _disposed = false;
  int _reconnectAttempt = 0;
  DateTime? _disconnectedAt;
  Timer? _reconnectTimer;
  Timer? _proactiveRefreshTimer;

  final Set<String> _activeConversationRooms = <String>{};
  final Map<String, String> _pendingMessageIds = <String, String>{};
  final LinkedHashSet<String> _seenEventIds = LinkedHashSet<String>();
  final LinkedHashSet<String> _seenMessageIds = LinkedHashSet<String>();
  static const _maxRememberedEventIds = 512;

  final _searchMatchedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _offerUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectedController = StreamController<void>.broadcast();
  final _reconnectedController = StreamController<void>.broadcast();
  final _authenticationRequiredController = StreamController<void>.broadcast();

  Stream<Map<String, dynamic>> get onSearchMatched =>
      _searchMatchedController.stream;
  Stream<Map<String, dynamic>> get onOfferUpdated =>
      _offerUpdatedController.stream;
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  Stream<Map<String, dynamic>> get onNotification =>
      _notificationController.stream;
  Stream<void> get onConnected => _connectedController.stream;
  Stream<void> get onReconnect => _reconnectedController.stream;
  Stream<void> get onAuthenticationRequired =>
      _authenticationRequiredController.stream;

  bool get isConnected => _socket?.connected == true;

  Future<void> connect({bool force = false}) async {
    if (_disposed) return;
    _shouldReconnect = true;
    if (force) {
      _disconnectedAt ??= DateTime.now();
      _disposeSocket();
    }
    await _openSocket();
  }

  Future<void> _openSocket() async {
    if (_disposed || !_shouldReconnect || _isConnecting) return;
    _isConnecting = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    try {
      final token = await _secureStorage.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('[SocketService] No access token available.');
        return;
      }
      if (_socket?.connected == true && _connectedToken == token) return;

      _disposeSocket();
      _connectedToken = token;
      final options = io.OptionBuilder()
          .setTransports(['websocket'])
          .enableForceNew()
          .disableAutoConnect()
          .disableReconnection()
          .setAuth({'token': token})
          .build();
      final socketUrl = _socketUrl();
      final socket = _socketFactory(socketUrl, options);
      _socket = socket;

      socket.onConnect((_) {
        _reconnectAttempt = 0;
        _requiresRefresh = false;
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
        _scheduleProactiveRefresh(token);
        for (final conversationId in _activeConversationRooms) {
          socket.emit(RealtimeClientEvent.join, {
            'conversationId': conversationId,
          });
        }

        _connectedController.add(null);

        final disconnectedAt = _disconnectedAt;
        _disconnectedAt = null;
        if (disconnectedAt != null &&
            DateTime.now().difference(disconnectedAt) >= _catchUpThreshold) {
          _reconnectedController.add(null);
        }
        debugPrint('[SocketService] Socket connected: ${socket.id}');
      });

      socket.onConnectError((error) {
        debugPrint('[SocketService] Socket connect error: $error');
        unawaited(_handleConnectError(error));
      });
      socket.onError((error) {
        debugPrint('[SocketService] Socket error: $error');
      });
      socket.on(RealtimeControlEvent.wsError, (error) {
        debugPrint('[SocketService] Realtime request rejected: $error');
        // The server's LRU cap deliberately evicts the oldest connection.
        // Reconnecting it would immediately evict the next device and create
        // an endless replacement loop across all devices.
        if (_extractErrorCode(error) == 'CONNECTION_REPLACED') {
          _shouldReconnect = false;
        }
      });
      socket.on(RealtimeControlEvent.authExpired, (_) {
        _disconnectedAt ??= DateTime.now();
        _requiresRefresh = true;
        unawaited(_refreshAndReconnect());
      });
      socket.onDisconnect((reason) {
        _proactiveRefreshTimer?.cancel();
        _proactiveRefreshTimer = null;
        _disconnectedAt ??= DateTime.now();
        debugPrint('[SocketService] Socket disconnected: $reason');
        _scheduleReconnect();
      });

      _bindDomainEvents(socket);
      socket.connect();
    } finally {
      _isConnecting = false;
    }
  }

  void _bindDomainEvents(io.Socket socket) {
    socket.on(RealtimeServerEvent.searchMatched, (raw) {
      final data = _eventData(RealtimeServerEvent.searchMatched, raw);
      if (data != null) _searchMatchedController.add(data);
    });
    socket.on(RealtimeServerEvent.offerNew, (raw) {
      final data = _eventData(RealtimeServerEvent.offerNew, raw);
      if (data != null) _offerUpdatedController.add(data);
    });
    socket.on(RealtimeServerEvent.offerUpdated, (raw) {
      final data = _eventData(RealtimeServerEvent.offerUpdated, raw);
      if (data != null) _offerUpdatedController.add(data);
    });
    socket.on(RealtimeServerEvent.notificationNew, (raw) {
      final data = _eventData(RealtimeServerEvent.notificationNew, raw);
      if (data != null) _notificationController.add(data);
    });
    socket.on(RealtimeServerEvent.messageNew, (raw) {
      final data = _eventData(RealtimeServerEvent.messageNew, raw);
      if (data != null) _publishMessage(data);
    });
  }

  Map<String, dynamic>? _eventData(String expectedName, Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    if (map['eventId'] is String && map['data'] is Map) {
      if (map['v'] != realtimeContractVersion || map['name'] != expectedName) {
        debugPrint('[SocketService] Ignored incompatible event: $map');
        return null;
      }
      final eventId = map['eventId'] as String;
      if (!_seenEventIds.add(eventId)) return null;
      if (_seenEventIds.length > _maxRememberedEventIds) {
        _seenEventIds.remove(_seenEventIds.first);
      }
      return Map<String, dynamic>.from(map['data'] as Map);
    }

    // One-release compatibility for a rolling backend/mobile deployment.
    return map;
  }

  Future<void> _handleConnectError(Object? error) async {
    final code = _extractErrorCode(error);
    _disposeSocket();
    switch (code) {
      case 'AUTH_TOKEN_EXPIRED':
      case 'AUTH_TOKEN_REQUIRED':
        _requiresRefresh = true;
        await _refreshAndReconnect();
        return;
      case 'AUTH_CONNECTION_LIMIT':
        _scheduleReconnect();
        return;
      case 'AUTH_ACCESS_TOKEN_REQUIRED':
      case 'AUTH_INVALID':
      case 'ACCOUNT_INACTIVE':
      case 'ACCOUNT_PENDING_APPROVAL':
        _shouldReconnect = false;
        await _tokenRefreshCoordinator.invalidateSession();
        return;
      default:
        _scheduleReconnect();
        return;
    }
  }

  String? _extractErrorCode(Object? error) {
    if (error is Map) {
      final code = error['code'];
      if (code is String) return code;
      return _extractErrorCode(error['data']);
    }
    try {
      final dynamic value = error;
      return _extractErrorCode(value.data);
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshAndReconnect() async {
    if (_disposed || !_shouldReconnect || _refreshInProgress) return;
    _refreshInProgress = true;
    _proactiveRefreshTimer?.cancel();
    _proactiveRefreshTimer = null;
    try {
      await _tokenRefreshCoordinator.refreshAccessToken();
      _requiresRefresh = false;
      _disconnectedAt ??= DateTime.now();
      _disposeSocket();
      await _openSocket();
    } on SessionInvalidatedException {
      _shouldReconnect = false;
      _disposeSocket();
    } on TokenRefreshUnavailableException {
      _requiresRefresh = true;
      _authenticationRequiredController.add(null);
      _scheduleReconnect();
    } finally {
      _refreshInProgress = false;
    }
  }

  void _scheduleReconnect() {
    if (_disposed || !_shouldReconnect || _reconnectTimer != null) return;
    final delay = _reconnectPolicy.delayForAttempt(_reconnectAttempt);
    _reconnectAttempt += 1;
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      if (_requiresRefresh) {
        unawaited(_refreshAndReconnect());
      } else {
        unawaited(_openSocket());
      }
    });
  }

  void _scheduleProactiveRefresh(String token) {
    _proactiveRefreshTimer?.cancel();
    final expiresAt = _jwtExpiration(token);
    if (expiresAt == null) return;
    final refreshAt = expiresAt.subtract(const Duration(minutes: 1));
    final delay = refreshAt.difference(DateTime.now());
    _proactiveRefreshTimer = Timer(
      delay.isNegative ? Duration.zero : delay,
      () {
        _requiresRefresh = true;
        unawaited(_refreshAndReconnect());
      },
    );
  }

  DateTime? _jwtExpiration(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload is Map ? payload['exp'] : null;
      return exp is num
          ? DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000)
          : null;
    } catch (_) {
      return null;
    }
  }

  void joinConversation(String conversationId) {
    _activeConversationRooms.add(conversationId);
    if (_socket?.connected == true) {
      _socket!.emit(RealtimeClientEvent.join, {
        'conversationId': conversationId,
      });
    }
  }

  void leaveConversation(String conversationId) {
    _activeConversationRooms.remove(conversationId);
    if (_socket?.connected == true) {
      _socket!.emit(RealtimeClientEvent.leave, {
        'conversationId': conversationId,
      });
    }
  }

  Future<bool> sendMessage(
    String conversationId,
    String content, {
    String type = 'text',
  }) async {
    if (_socket?.connected != true) return false;
    const maxAttempts = 2;
    final commandKey = '$conversationId\u0000$type\u0000$content';
    final clientMessageId = _pendingMessageIds.putIfAbsent(
      commandKey,
      () => const Uuid().v4(),
    );
    try {
      for (var attempt = 0; attempt < maxAttempts; attempt += 1) {
        if (_socket?.connected != true) return false;
        try {
          final confirmed = await _sendMessageAttempt(
            conversationId,
            content,
            type,
            clientMessageId,
          ).timeout(_messageAckTimeout);
          _pendingMessageIds.remove(commandKey);
          return confirmed;
        } on TimeoutException {
          if (attempt == maxAttempts - 1) {
            throw const RealtimeRequestException(
              'ACK_TIMEOUT',
              'No se pudo confirmar el mensaje. Verifica tu conexión.',
            );
          }
        }
      }
    } on RealtimeRequestException catch (error) {
      // An ACK timeout is ambiguous, so keep the command id for a manual
      // retry. Any server rejection is definitive and can release it.
      if (error.code != 'ACK_TIMEOUT') _pendingMessageIds.remove(commandKey);
      rethrow;
    }
    return false;
  }

  Future<bool> _sendMessageAttempt(
    String conversationId,
    String content,
    String type,
    String clientMessageId,
  ) {
    final completer = Completer<bool>();
    _socket!.emitWithAck(
      RealtimeClientEvent.messageSend,
      {
        'clientMessageId': clientMessageId,
        'conversationId': conversationId,
        'content': content,
        'type': type,
      },
      ack: (data) {
        if (data is Map && data['status'] == 'ok') {
          final rawMessage = data['message'];
          if (!_disposed && rawMessage is Map) {
            _publishMessage(Map<String, dynamic>.from(rawMessage));
          }
          completer.complete(true);
        } else {
          completer.completeError(RealtimeRequestException.fromAck(data));
        }
      },
    );
    return completer.future;
  }

  void disconnect() {
    _shouldReconnect = false;
    _requiresRefresh = false;
    _reconnectAttempt = 0;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _proactiveRefreshTimer?.cancel();
    _proactiveRefreshTimer = null;
    _activeConversationRooms.clear();
    _pendingMessageIds.clear();
    _seenEventIds.clear();
    _seenMessageIds.clear();
    _disconnectedAt = null;
    _disposeSocket();
  }

  void _publishMessage(Map<String, dynamic> message) {
    final id = message['id'];
    if (id is String && id.isNotEmpty) {
      if (!_seenMessageIds.add(id)) return;
      if (_seenMessageIds.length > _maxRememberedEventIds) {
        _seenMessageIds.remove(_seenMessageIds.first);
      }
    }
    _messageController.add(message);
  }

  void _disposeSocket() {
    final socket = _socket;
    _socket = null;
    _connectedToken = null;
    if (socket == null) return;

    socket.off('connect');
    socket.off('connect_error');
    socket.off('error');
    socket.off('disconnect');
    socket.off(RealtimeControlEvent.wsError);
    socket.off(RealtimeControlEvent.authExpired);
    for (final event in const [
      RealtimeServerEvent.searchMatched,
      RealtimeServerEvent.offerNew,
      RealtimeServerEvent.offerUpdated,
      RealtimeServerEvent.notificationNew,
      RealtimeServerEvent.messageNew,
    ]) {
      socket.off(event);
    }
    socket.disconnect();
    socket.dispose();
  }

  String _socketUrl() {
    var url = AppConfig.apiBaseUrl.replaceAll('/api', '');
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);
    return url;
  }

  void dispose() {
    if (_disposed) return;
    disconnect();
    _disposed = true;
    _searchMatchedController.close();
    _offerUpdatedController.close();
    _messageController.close();
    _notificationController.close();
    _connectedController.close();
    _reconnectedController.close();
    _authenticationRequiredController.close();
  }
}
