import '../../domain/entities/user_notification.dart';

class UserNotificationModel extends UserNotification {
  const UserNotificationModel({
    required super.id,
    required super.type,
    required super.title,
    required super.body,
    required super.data,
    required super.isRead,
    required super.createdAt,
  });

  factory UserNotificationModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : const <String, dynamic>{};

    return UserNotificationModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      type: json['tipo']?.toString() ?? '',
      title: json['titulo']?.toString() ?? '',
      body: json['cuerpo']?.toString() ?? '',
      data: data,
      isRead: json['leido'] == true,
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
    );
  }

  static DateTime _parseDate(Object? rawDate) {
    if (rawDate is DateTime) return rawDate;
    if (rawDate != null) {
      final parsed = DateTime.tryParse(rawDate.toString());
      if (parsed != null) return parsed;
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}
