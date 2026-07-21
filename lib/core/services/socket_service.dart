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
  final SecureStorage _secureStorage;

  SocketService(this._secureStorage);

  // Streams for events
  final _searchMatchedController = StreamController<Map<String, dynamic>>.broadcast();
  final _offerUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Chat events
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingStartController = StreamController<String>.broadcast();
  final _typingStopController = StreamController<String>.broadcast();

  Stream<Map<String, dynamic>> get onSearchMatched => _searchMatchedController.stream;
  Stream<Map<String, dynamic>> get onOfferUpdated => _offerUpdatedController.stream;
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  Stream<String> get onTypingStart => _typingStartController.stream;
  Stream<String> get onTypingStop => _typingStopController.stream;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await _secureStorage.getToken();
    if (token == null) {
      debugPrint('No token found in secure storage. Cannot connect socket.');
      return;
    }

    // Remove /api from base url if it exists for socket connection
    String socketUrl = AppConfig.apiBaseUrl.replaceAll('/api', '');
    if (socketUrl.endsWith('/')) {
      socketUrl = socketUrl.substring(0, socketUrl.length - 1);
    }

    _socket = io.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token},
    });

    debugPrint('Attempting to connect socket to: $socketUrl');

    _socket?.onConnect((_) {
      debugPrint('Socket connected: ${_socket?.id}');
    });

    _socket?.onConnectError((error) {
      debugPrint('Socket connect error: $error');
    });

    _socket?.onError((error) {
      debugPrint('Socket error: $error');
    });

    _socket?.onDisconnect((_) {
      debugPrint('Socket disconnected');
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
        } else if (tipo == 'offer.updated' || tipo == 'offer.new') {
          _offerUpdatedController.add(Map<String, dynamic>.from(payloadData));
        } else if (tipo == 'message.new') {
          // Si el mensaje llega vía notificación en vez del chat gateway
          _messageController.add(Map<String, dynamic>.from(payloadData));
        }
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
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
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
  }
}
