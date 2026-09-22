import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifications/notification_provider.dart';
import '../notifications/notification_type.dart';

extension BuildContextExtensions on BuildContext {
  void showSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
    String? title,
    Duration? duration,
    bool clearQueue = true,
  }) {
    try {
      final container = ProviderScope.containerOf(this);
      final notifier = container.read(notificationProvider.notifier);
      if (clearQueue) notifier.dismissAll();

      final type = isError
          ? NotificationType.error
          : (isSuccess ? NotificationType.success : NotificationType.info);

      notifier.show(
        type: type,
        message: message,
        title: title,
        duration: duration,
      );
    } catch (_) {
      final messenger = ScaffoldMessenger.of(this);
      if (clearQueue) messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? Theme.of(this).colorScheme.error
              : (isSuccess ? Colors.green : null),
          duration: duration ?? const Duration(seconds: 4),
        ),
      );
    }
  }
}
