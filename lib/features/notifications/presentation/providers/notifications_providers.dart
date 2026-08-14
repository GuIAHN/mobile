import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/notifications_remote_datasource.dart';

final notificationsRemoteDatasourceProvider =
    Provider<NotificationsRemoteDatasource>((ref) {
  return NotificationsRemoteDatasource(ref.watch(dioClientProvider));
});

final unreadNotificationsCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(notificationsRemoteDatasourceProvider).getUnreadCount();
});
