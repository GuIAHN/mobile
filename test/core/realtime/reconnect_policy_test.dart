import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/realtime/reconnect_policy.dart';

void main() {
  test('uses exponential backoff capped at thirty seconds', () {
    const policy = ReconnectPolicy();

    expect(
      List.generate(8, policy.delayForAttempt),
      const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 4),
        Duration(seconds: 8),
        Duration(seconds: 16),
        Duration(seconds: 30),
        Duration(seconds: 30),
        Duration(seconds: 30),
      ],
    );
  });
}
