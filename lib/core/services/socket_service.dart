import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';

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

  SocketService(this._secureStorage);

  // Streams for events
  final _searchMatchedController = StreamController<Map<String, dynamic>>.broadcast();
  final _offerUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Chat events
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingStartController = StreamController<String>.broadcast();
  final _typingStopController = StreamController<String>.broadcast();

  // Notificación genérica: se emite para CUALQUIER tipo de notification.new,
  // incluso las que no tienen un stream específico (offer.inquiry,
  // user.approved, settlement.*, etc.). Úsese para refrescar badges/listas
  // de notificaciones en tiempo real.
  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onSearchMatched => _searchMatchedController.stream;
  Stream<Map<String, dynamic>> get onOfferUpdated => _offerUpdatedController.stream;
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  Stream<String> get onTypingStart => _typingStartController.stream;
  Stream<String> get onTypingStop => _typingStopController.stream;
  Stream<Map<String, dynamic>> get onNotification => _notificationController.stream;

  bool _isConnecting = false;

  Future<void> connect() async {
    if (_isConnecting) return;
    _isConnecting = true;

    try {
      final token = await _secureStorage.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('[SocketService] No token found in secure storage. Disconnecting socket.');
        disconnect();
        return;
      }

      if (_socket != null && _socket!.connected && _connectedToken == token) {
        return;
      }

      debugPrint('[SocketService] Connecting socket with token hash: ${token.hashCode}');
      disconnect();
      _connectedToken = token;

      // Remove /api from base url if it exists for socket connection
      String socketUrl = AppConfig.apiBaseUrl.replaceAll('/api', '');
      if (socketUrl.endsWith('/')) {
        socketUrl = socketUrl.substring(0, socketUrl.length - 1);
      }

      _socket = io.io(
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
      });

      _socket?.onConnectError((error) {
        debugPrint('[SocketService] Socket connect error: $error');
      });

      _socket?.onError((error) {
        debugPrint('[SocketService] Socket error: $error');
      });

      _socket?.onDisconnect((reason) {
        debugPrint('[SocketService] Socket disconnected: $reason');
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
            _searchMatchedController.add(Map<String, dynamic>.from(payloadData));
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

  Future<bool> sendMessage(String conversationId, String content, {String type = 'text'}) async {
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
          completer.completeError(data?['error'] ?? 'Error desconocido al enviar');
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
    _messageController.close();
    _typingStartController.close();
    _typingStopController.close();
    _notificationController.close();
  }
}
