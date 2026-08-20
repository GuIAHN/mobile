import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/network/token_refresh_coordinator.dart';
import 'package:guiautomotriz_mobile/core/realtime/reconnect_policy.dart';
import 'package:guiautomotriz_mobile/core/services/socket_service.dart';
import 'package:guiautomotriz_mobile/core/storage/secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:socket_io_client/src/manager.dart';

class _MockSecureStorage extends Mock implements SecureStorage {}

class _MockTokenRefreshCoordinator extends Mock
    implements TokenRefreshCoordinator {}

class _MockSocket extends Mock implements io.Socket {}

class _MockManager extends Mock implements Manager {}

class _SocketHarness {
  _SocketHarness(this.id) {
    when(() => socket.io).thenReturn(manager);
    when(() => socket.id).thenReturn(id);
    when(() => socket.connected).thenAnswer((_) => connected);
    when(() => socket.on(any(), any())).thenAnswer((invocation) {
      handlers[invocation.positionalArguments[0] as String] =
          invocation.positionalArguments[1] as void Function(dynamic);
      return () {};
    });
    when(() => manager.on(any(), any())).thenAnswer((_) => () {});
    when(() => socket.connect()).thenAnswer((_) => socket);
    when(() => socket.disconnect()).thenAnswer((_) {
      connected = false;
      return socket;
    });
    when(() => socket.dispose()).thenAnswer((_) {});
    when(() => socket.off(any())).thenAnswer((_) {});
    when(() => socket.emit(any(), any())).thenAnswer((_) {});
  }

  final String id;
  final socket = _MockSocket();
  final manager = _MockManager();
  final handlers = <String, void Function(dynamic)>{};
  bool connected = false;

  void trigger(String event, [Object? data]) {
    if (event == 'connect') connected = true;
    handlers[event]!(data);
  }
}

void main() {
  test('parses the sanitized realtime ACK without exposing its map shape', () {
    final error = RealtimeRequestException.fromAck({
      'status': 'error',
      'error': {
        'code': 'CONTENT_REJECTED',
        'message': 'No se permite compartir enlaces externos.',
      },
    });

    expect(error.code, 'CONTENT_REJECTED');
    expect(error.message, 'No se permite compartir enlaces externos.');
    expect(error.toString(), 'No se permite compartir enlaces externos.');
    expect(error.toString(), isNot(contains('{code:')));
  });

  test('keeps compatibility with the previous string ACK', () {
    final error = RealtimeRequestException.fromAck({
      'status': 'error',
      'error': 'Error temporal',
    });

    expect(error.code, 'REQUEST_REJECTED');
    expect(error.message, 'Error temporal');
  });

  group('SocketService lifecycle', () {
    late _MockSecureStorage storage;
    late _MockTokenRefreshCoordinator coordinator;
    late _SocketHarness first;
    late _SocketHarness second;
    late SocketService service;
    var accessToken = 'not-a-jwt';
    var factoryCalls = 0;

    setUp(() {
      storage = _MockSecureStorage();
      coordinator = _MockTokenRefreshCoordinator();
      first = _SocketHarness('socket-1');
      second = _SocketHarness('socket-2');
      factoryCalls = 0;
      accessToken = 'not-a-jwt';
      when(() => storage.getToken()).thenAnswer((_) async => accessToken);
      when(() => coordinator.refreshAccessToken()).thenAnswer((_) async {
        accessToken = 'rotated-not-a-jwt';
        return accessToken;
      });
      when(() => coordinator.invalidateSession()).thenAnswer((_) async {});
      service = SocketService(
        storage,
        coordinator,
        socketFactory: (_, __) {
          final harness = factoryCalls++ == 0 ? first : second;
          return harness.socket;
        },
        reconnectPolicy: const ReconnectPolicy(
          initialDelay: Duration(milliseconds: 1),
          maxDelay: Duration(milliseconds: 1),
        ),
        messageAckTimeout: const Duration(milliseconds: 1),
      );
    });

    tearDown(() => service.dispose());

    test('publishes every successful connection for dependent providers',
        () async {
      final connected = service.onConnected.first;

      await service.connect();
      first.trigger('connect');

      await connected;
      expect(service.isConnected, isTrue);
    });

    test('queues joins, re-joins after token refresh, and emits catch-up',
        () async {
      service.joinConversation('conversation-1');
      final catchUp = service.onReconnect.first;

      await service.connect();
      first.trigger('connect');
      verify(
        () => first.socket.emit('join', {
          'conversationId': 'conversation-1',
        }),
      ).called(1);

      first.trigger('auth.expired', {'code': 'AUTH_TOKEN_EXPIRED'});
      await pumpEventQueue();
      verify(() => coordinator.refreshAccessToken()).called(1);
      verify(() => second.socket.connect()).called(1);

      second.trigger('connect');
      await catchUp;
      verify(
        () => second.socket.emit('join', {
          'conversationId': 'conversation-1',
        }),
      ).called(1);
    });

    test('drops repeated versioned eventIds before publishing to consumers',
        () async {
      final received = <Map<String, dynamic>>[];
      final sub = service.onMessage.listen(received.add);
      await service.connect();
      first.trigger('connect');
      final envelope = {
        'eventId': 'event-1',
        'name': 'message.new',
        'v': 1,
        'occurredAt': '2026-08-20T00:00:00.000Z',
        'data': {
          'id': 'message-1',
          'conversationId': 'conversation-1',
        },
      };

      first.trigger('message.new', envelope);
      first.trigger('message.new', envelope);
      await pumpEventQueue();

      expect(received, hasLength(1));
      expect(received.single['id'], 'message-1');
      await sub.cancel();
    });

    test('retries a lost ACK with the same client message id', () async {
      final clientMessageIds = <String>[];
      final received = <Map<String, dynamic>>[];
      final subscription = service.onMessage.listen(received.add);
      var attempts = 0;
      when(
        () => first.socket.emitWithAck(
          any(),
          any(),
          ack: any(named: 'ack'),
        ),
      ).thenAnswer((invocation) {
        attempts += 1;
        final payload = invocation.positionalArguments[1] as Map;
        clientMessageIds.add(payload['clientMessageId'] as String);
        if (attempts == 2) {
          final message = {
            'id': 'message-1',
            'conversationId': 'conversation-1',
            'senderId': 'user-1',
            'senderName': 'User One',
            'content': 'hola',
            'type': 'text',
            'read': false,
            'createdAt': '2026-08-20T12:00:00.000Z',
          };
          final envelope = {
            'eventId': 'stable-event-1',
            'name': 'message.new',
            'v': 1,
            'occurredAt': '2026-08-20T12:00:00.000Z',
            'data': message,
          };
          first.trigger('message.new', envelope);
          first.trigger('message.new', envelope);
          final ack = invocation.namedArguments[#ack] as Function;
          ack({
            'status': 'ok',
            'messageId': 'message-1',
            'message': message,
          });
        }
      });
      await service.connect();
      first.trigger('connect');

      await expectLater(
        service.sendMessage('conversation-1', 'hola'),
        completion(true),
      );

      expect(clientMessageIds, hasLength(2));
      expect(clientMessageIds.toSet(), hasLength(1));
      expect(received, hasLength(1));
      expect(received.single['id'], 'message-1');
      await subscription.cancel();
    });

    test('keeps the command id for a manual retry after both ACKs time out',
        () async {
      final clientMessageIds = <String>[];
      var attempts = 0;
      when(
        () => first.socket.emitWithAck(
          any(),
          any(),
          ack: any(named: 'ack'),
        ),
      ).thenAnswer((invocation) {
        attempts += 1;
        final payload = invocation.positionalArguments[1] as Map;
        clientMessageIds.add(payload['clientMessageId'] as String);
        if (attempts == 3) {
          final ack = invocation.namedArguments[#ack] as Function;
          ack({'status': 'ok', 'messageId': 'message-1'});
        }
      });
      await service.connect();
      first.trigger('connect');

      await expectLater(
        service.sendMessage('conversation-1', 'hola'),
        throwsA(
          isA<RealtimeRequestException>().having(
            (error) => error.code,
            'code',
            'ACK_TIMEOUT',
          ),
        ),
      );
      await expectLater(
        service.sendMessage('conversation-1', 'hola'),
        completion(true),
      );

      expect(clientMessageIds, hasLength(3));
      expect(clientMessageIds.toSet(), hasLength(1));
    });

    test('leave removes a queued room and emits leave while connected',
        () async {
      service.joinConversation('conversation-1');
      await service.connect();
      first.trigger('connect');

      service.leaveConversation('conversation-1');

      verify(
        () => first.socket.emit('leave', {
          'conversationId': 'conversation-1',
        }),
      ).called(1);
    });

    test('does not reconnect a socket deliberately replaced by the LRU cap',
        () async {
      await service.connect();
      first.trigger('connect');

      first.trigger('ws.error', {'code': 'CONNECTION_REPLACED'});
      first.trigger('disconnect', 'io server disconnect');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(factoryCalls, 1);
      verifyNever(() => second.socket.connect());
    });
  });
}
