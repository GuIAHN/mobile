import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';

class NotificationsRemoteDatasource {
  final DioClient _client;

  NotificationsRemoteDatasource(this._client);

  Future<int> getUnreadCount() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.notificationsUnreadCount,
    );
    final count = response.data?['count'];
    if (count is num) return count.toInt();
    return int.tryParse(count?.toString() ?? '') ?? 0;
  }
}
