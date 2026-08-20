import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/realtime/event_names.dart';

void main() {
  test('Dart event names match the backend contract manifest', () {
    final manifest = jsonDecode(
      File('../backend/src/shared/realtime/events.manifest.json')
          .readAsStringSync(),
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
