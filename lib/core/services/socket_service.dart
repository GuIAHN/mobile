import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

class SocketService {
  io.Socket? _socket;
  final _secureStorage = const FlutterSecureStorage();

  // Streams for events
  final _searchMatchedController = StreamController<Map<String, dynamic>>.broadcast();
  final _offerUpdatedController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onSearchMatched => _searchMatchedController.stream;
  Stream<Map<String, dynamic>> get onOfferUpdated => _offerUpdatedController.stream;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await _secureStorage.read(key: 'jwt_token');
    if (token == null) return;

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

    _socket?.onConnect((_) {
      debugPrint('Socket connected: ${_socket?.id}');
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

    _socket?.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _searchMatchedController.close();
    _offerUpdatedController.close();
  }
}
