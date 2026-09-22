import 'package:equatable/equatable.dart';

/// A notification persisted for the authenticated user.
///
/// This is deliberately separate from the ephemeral toast model in
/// `core/notifications`.
class UserNotification extends Equatable {
  const UserNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        body,
        data,
        isRead,
        createdAt,
      ];
}
