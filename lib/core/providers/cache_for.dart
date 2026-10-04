import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keeps an auto-disposed provider warm for [duration] after it is created.
///
/// Active listeners always keep the provider alive. Once the retention window
/// expires, Riverpod disposes it as soon as the last listener leaves, allowing
/// a later visit to refresh stale data without reloading on every tab switch.
extension AutoDisposeRefCache on Ref {
  void cacheFor(Duration duration) {
    final link = keepAlive();
    final timer = Timer(duration, link.close);
    onDispose(timer.cancel);
  }
}
