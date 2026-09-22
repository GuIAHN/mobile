import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/realtime/event_names.dart';

void main() {
  test('Dart event names match the backend contract manifest', () {
    final candidates = [
      '../GuIA-HN-Backend/backend/src/shared/realtime/events.manifest.json',
      '../GuIA-HN-Backend/src/shared/realtime/events.manifest.json',
      '../backend/src/shared/realtime/events.manifest.json',
    ];
    final manifestFile = candidates.map(File.new).firstWhere(
          (file) => file.existsSync(),
          orElse: () => throw StateError(
            'Backend realtime manifest not found in: ${candidates.join(', ')}',
          ),
        );
    final manifest = jsonDecode(
      manifestFile.readAsStringSync(),
    ) as Map<String, dynamic>;

    expect(manifest['version'], realtimeContractVersion);
    expect(manifest['client'], [
      RealtimeClientEvent.join,
      RealtimeClientEvent.leave,
      RealtimeClientEvent.messageSend,
      RealtimeClientEvent.typingStart,
      RealtimeClientEvent.typingStop,
    ]);
    expect(manifest['server'], [
      RealtimeServerEvent.searchMatched,
      RealtimeServerEvent.offerNew,
      RealtimeServerEvent.offerUpdated,
      RealtimeServerEvent.reviewCreated,
      RealtimeServerEvent.messageNew,
      RealtimeServerEvent.notificationNew,
      RealtimeServerEvent.typingStart,
      RealtimeServerEvent.typingStop,
    ]);
    expect(manifest['control'], [
      RealtimeControlEvent.authExpired,
      RealtimeControlEvent.wsError,
    ]);
  });
}
