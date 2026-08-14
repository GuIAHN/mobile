import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_notification_model.dart';

class NotificationsRemoteDatasource {
  final DioClient _client;

  NotificationsRemoteDatasource(this._client);

  Future<List<UserNotificationModel>> getUnreadNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _client.get<List<dynamic>>(
      ApiEndpoints.notifications,
      queryParameters: {
        'leido': false,
        'page': page,
        'limit': limit,
      },
    );

    return (response.data ?? const <dynamic>[])
        .whereType<Map>()
        .map(
          (json) => UserNotificationModel.fromJson(
            Map<String, dynamic>.from(json),
          ),
        )
        .toList(growable: false);
  }

  Future<void> markRead(String id) async {
    await _client.patch<Map<String, dynamic>>(
      ApiEndpoints.notificationRead(id),
    );
  }

  Future<void> markAllRead() async {
    await _client.patch<Map<String, dynamic>>(
      ApiEndpoints.notificationsReadAll,
    );
  }

  Future<int> getUnreadCount() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.notificationsUnreadCount,
    );
    final count = response.data?['count'];
    if (count is num) return count.toInt();
    return int.tryParse(count?.toString() ?? '') ?? 0;
  }
}
