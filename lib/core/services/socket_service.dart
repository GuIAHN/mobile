import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';

typedef SocketFactory = io.Socket Function(dynamic uri, dynamic options);

final socketServiceProvider = Provider<SocketService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final service = SocketService(secureStorage);
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

class SocketService {
  io.Socket? _socket;
  String? _connectedToken;
  final SecureStorage _secureStorage;
  final SocketFactory _socketFactory;

  SocketService(
    this._secureStorage, {
    SocketFactory? socketFactory,
  }) : _socketFactory =
            socketFactory ?? ((uri, options) => io.io(uri, options));

  // Streams for events
  final _searchMatchedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _offerUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectedController = StreamController<void>.broadcast();
  final _authenticationRequiredController = StreamController<void>.broadcast();

  // Chat events
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingStartController = StreamController<String>.broadcast();
  final _typingStopController = StreamController<String>.broadcast();

  // Notificación genérica: se emite para CUALQUIER tipo de notification.new,
  // incluso las que no tienen un stream específico (offer.inquiry,
  // user.approved, settlement.*, etc.). Úsese para refrescar badges/listas
  // de notificaciones en tiempo real.
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onSearchMatched =>
      _searchMatchedController.stream;
  Stream<Map<String, dynamic>> get onOfferUpdated =>
      _offerUpdatedController.stream;
  Stream<void> get onConnected => _connectedController.stream;
  Stream<void> get onAuthenticationRequired =>
      _authenticationRequiredController.stream;
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  Stream<String> get onTypingStart => _typingStartController.stream;
  Stream<String> get onTypingStop => _typingStopController.stream;
  Stream<Map<String, dynamic>> get onNotification =>
      _notificationController.stream;

  bool _isConnecting = false;
  String? _lastRejectedToken;

  bool get isConnected => _socket?.connected == true;

  /// Connects with the latest access token from secure storage.
  ///
  /// [force] recreates the transport even if Socket.IO still reports an
  /// active connection. This is used after the app resumes so the server
  /// authenticates the session again and consumers can resync missed events.
  Future<void> connect({bool force = false}) async {
    if (_isConnecting) return;
    _isConnecting = true;

    try {
      final token = await _secureStorage.getToken();
      if (token == null || token.isEmpty) {
        debugPrint(
            '[SocketService] No token found in secure storage. Disconnecting socket.');
        disconnect();
        return;
      }

      if (!force &&
          _socket != null &&
          _connectedToken == token &&
          (_socket!.connected || _socket!.active)) {
        return;
      }

      debugPrint(
          '[SocketService] Connecting socket with token hash: ${token.hashCode}');
      if (_connectedToken != token) {
        _lastRejectedToken = null;
      }
      disconnect();
      _connectedToken = token;

      // Remove /api from base url if it exists for socket connection
      String socketUrl = AppConfig.apiBaseUrl.replaceAll('/api', '');
      if (socketUrl.endsWith('/')) {
        socketUrl = socketUrl.substring(0, socketUrl.length - 1);
      }

      _socket = _socketFactory(
        socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableForceNew()
            .disableAutoConnect()
            .setAuth({'token': token})
            .setQuery({'token': token})
            .build(),
      );

      _socket?.onConnect((_) {
        debugPrint('[SocketService] Socket connected: ${_socket?.id}');
        _connectedController.add(null);
      });

      _socket?.onConnectError((error) {
        debugPrint('[SocketService] Socket connect error: $error');
        if (_looksLikeAuthenticationError(error)) {
          _requestAuthenticationRecovery();
        }
      });

      _socket?.onError((error) {
        debugPrint('[SocketService] Socket error: $error');
      });

      _socket?.onDisconnect((reason) {
        debugPrint('[SocketService] Socket disconnected: $reason');
        // A server-side disconnect disables Socket.IO's automatic reconnect.
        // The most common cause here is a JWT that expired while the app was
        // backgrounded or the network was unavailable.
        if (reason?.toString() == 'io server disconnect') {
          _requestAuthenticationRecovery();
        }
      });

      _socket?.on('search.matched', (data) {
        debugPrint('Received search.matched: $data');
        if (data != null && data['data'] != null) {
          _searchMatchedController.add(Map<String, dynamic>.from(data['data']));
        } else if (data is Map) {
          _searchMatchedController.add(Map<String, dynamic>.from(data));
        }
      });

      _socket?.on('offer.updated', (data) {
        debugPrint('Received offer.updated: $data');
        if (data != null && data['data'] != null) {
          _offerUpdatedController.add(Map<String, dynamic>.from(data['data']));
        } else if (data is Map) {
          _offerUpdatedController.add(Map<String, dynamic>.from(data));
        }
      });

      _socket?.on('notification.new', (data) {
        debugPrint('Received notification.new: $data');
        if (data != null && data is Map) {
          final tipo = data['tipo'];
          final payloadData = data['data'] ?? data;

          if (tipo == 'search.matched') {
            _searchMatchedController
                .add(Map<String, dynamic>.from(payloadData));
          } else if (tipo == 'offer.updated' ||
              tipo == 'offer.new' ||
              tipo == 'offer.inquiry' ||
              tipo == 'offer.bought' ||
              tipo == 'offer.delivered') {
            _offerUpdatedController.add(Map<String, dynamic>.from(payloadData));
          } else if (tipo == 'message.new') {
            _messageController.add(Map<String, dynamic>.from(payloadData));
          }

          // Siempre emitir en el stream genérico, independientemente del
          // tipo, para que badges/listas de notificaciones se refresquen.
          _notificationController.add(Map<String, dynamic>.from(data));
        }
      });

      _socket?.on('message.new', (data) {
        if (data != null && data is Map) {
          _messageController.add(Map<String, dynamic>.from(data));
        }
      });

      _socket?.on('typing.start', (data) {
        if (data != null && data['userId'] != null) {
          _typingStartController.add(data['userId'].toString());
        }
      });

      _socket?.on('typing.stop', (data) {
        if (data != null && data['userId'] != null) {
          _typingStopController.add(data['userId'].toString());
        }
      });

      _socket?.connect();
    } finally {
      _isConnecting = false;
    }
  }

  bool _looksLikeAuthenticationError(dynamic error) {
    final message = error?.toString().toLowerCase() ?? '';
    return message.contains('token') ||
        message.contains('jwt') ||
        message.contains('auth') ||
        message.contains('unauthorized') ||
        message.contains('expired') ||
        message.contains('invalid');
  }

  void _requestAuthenticationRecovery() {
    final token = _connectedToken;
    if (token == null || token == _lastRejectedToken) return;
    _lastRejectedToken = token;
    _authenticationRequiredController.add(null);
  }

  void disconnect() {
    if (_socket != null) {
      debugPrint('[SocketService] Disconnecting socket...');
      _socket!.off('connect');
      _socket!.off('connect_error');
      _socket!.off('error');
      _socket!.off('disconnect');
      _socket!.off('search.matched');
      _socket!.off('offer.updated');
      _socket!.off('notification.new');
      _socket!.off('message.new');
      _socket!.off('typing.start');
      _socket!.off('typing.stop');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _connectedToken = null;
  }

  void joinConversation(String conversationId) {
    if (_socket?.connected == true) {
      _socket!.emit('join', {'conversationId': conversationId});
    }
  }

  Future<bool> sendMessage(String conversationId, String content,
      {String type = 'text'}) async {
    if (_socket?.connected == true) {
      final completer = Completer<bool>();
      _socket!.emitWithAck('message.send', {
        'conversationId': conversationId,
        'content': content,
        'type': type,
      }, ack: (data) {
        if (data != null && data['status'] == 'ok') {
          completer.complete(true);
        } else {
          completer
              .completeError(data?['error'] ?? 'Error desconocido al enviar');
        }
      });
      return completer.future;
    }
    return false;
  }

  void sendTypingStart(String conversationId) {
    if (_socket?.connected == true) {
      _socket!.emit('typing.start', {'conversationId': conversationId});
    }
  }

  void sendTypingStop(String conversationId) {
    if (_socket?.connected == true) {
      _socket!.emit('typing.stop', {'conversationId': conversationId});
    }
  }

  void dispose() {
    disconnect();
    _searchMatchedController.close();
    _offerUpdatedController.close();
    _connectedController.close();
    _authenticationRequiredController.close();
    _messageController.close();
    _typingStartController.close();
    _typingStopController.close();
    _notificationController.close();
  }
}
