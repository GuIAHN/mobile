import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/services/socket_service.dart';
import 'package:guiautomotriz_mobile/core/storage/secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:socket_io_client/src/manager.dart';

class _MockSecureStorage extends Mock implements SecureStorage {}

class _MockSocket extends Mock implements io.Socket {}

class _MockManager extends Mock implements Manager {}

void main() {
  late _MockSecureStorage storage;
  late _MockSocket socket;
  late _MockManager manager;
  late Map<String, dynamic Function(dynamic)> handlers;
  late Map<String, dynamic> connectionOptions;

  setUp(() {
    storage = _MockSecureStorage();
    socket = _MockSocket();
    manager = _MockManager();
    handlers = <String, dynamic Function(dynamic)>{};
    connectionOptions = <String, dynamic>{};

    when(() => storage.getToken()).thenAnswer((_) async => 'access-token-1');
    when(() => socket.connected).thenReturn(false);
    when(() => socket.active).thenReturn(false);
    when(() => socket.io).thenReturn(manager);
    when(() => socket.on(any(), any())).thenAnswer((invocation) {
      final event = invocation.positionalArguments[0] as String;
      final handler =
          invocation.positionalArguments[1] as dynamic Function(dynamic);
      handlers[event] = handler;
      return () {};
    });
    when(() => manager.on(any(), any())).thenReturn(() {});
    when(() => socket.connect()).thenReturn(socket);
    when(() => socket.disconnect()).thenReturn(socket);
    when(() => socket.dispose()).thenReturn(null);
    when(() => socket.off(any())).thenReturn(null);
  });

  SocketService createService() {
    return SocketService(
      storage,
      socketFactory: (uri, options) {
        connectionOptions = Map<String, dynamic>.from(options as Map);
        return socket;
      },
    );
  }

  test('connects with the latest token and publishes successful connection',
      () async {
    final service = createService();
    addTearDown(service.dispose);
    final connected = Completer<void>();
    final sub = service.onConnected.listen((_) => connected.complete());
    addTearDown(sub.cancel);

    await service.connect();

    expect(connectionOptions['auth'], {'token': 'access-token-1'});
    expect(connectionOptions['query'], {'token': 'access-token-1'});
    verify(() => socket.connect()).called(1);

    handlers['connect']!(null);
    await connected.future;
  });

  test('requests authentication recovery once for a rejected token', () async {
    final service = createService();
    addTearDown(service.dispose);
    var recoveryRequests = 0;
    final sub = service.onAuthenticationRequired.listen((_) {
      recoveryRequests++;
    });
    addTearDown(sub.cancel);

    await service.connect();
    handlers['disconnect']!('io server disconnect');
    handlers['disconnect']!('io server disconnect');
    await pumpEventQueue();

    expect(recoveryRequests, 1);
  });
}
