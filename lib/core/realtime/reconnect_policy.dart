import 'dart:math' as math;

class ReconnectPolicy {
  const ReconnectPolicy({
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
  });

  final Duration initialDelay;
  final Duration maxDelay;

  Duration delayForAttempt(int attempt) {
    final multiplier = math.pow(2, math.max(0, attempt)).toInt();
    final milliseconds = initialDelay.inMilliseconds * multiplier;
    return Duration(
      milliseconds: math.min(milliseconds, maxDelay.inMilliseconds),
    );
  }
}
