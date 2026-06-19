import '../../domain/entities/user.dart';

/// User model with JSON serialization.
/// Extends the [User] entity without polluting it.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    super.avatarUrl,
    super.phone,
    super.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String? parsedPhone;
    if (json['phone'] != null) {
      if (json['phone'] is Map) {
        parsedPhone = (json['phone'] as Map)['number'] as String?;
      } else if (json['phone'] is String) {
        parsedPhone = json['phone'] as String?;
      }
    }

    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String? ?? json['fullName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? json['photo'] as String?,
      phone: parsedPhone,
      role: json['role'] as String? ?? json['userType'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (phone != null) 'phone': phone,
        if (role != null) 'role': role,
      };
}

/// Complete login response containing tokens and user information.
class LoginResponseModel {
  final String accessToken;
  final String? refreshToken;
  final UserModel? user;

  const LoginResponseModel({
    required this.accessToken,
    this.refreshToken,
    this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}
