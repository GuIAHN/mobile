import '../../domain/entities/user.dart';
import '../../../../core/domain/enums/user_role.dart';
import '../../../vehicles/data/models/user_car_model.dart';

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
    super.approved,
    super.latitude,
    super.longitude,
    super.cars,
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

    final roleStr = json['role'] as String? ?? json['userType'] as String?;

    double? lat;
    double? lon;
    if (json['location'] != null && json['location'] is Map) {
      lat = (json['location']['lat'] as num?)?.toDouble();
      lon = (json['location']['lon'] as num?)?.toDouble();
    }

    List<UserCarModel>? parsedCars;
    if (json['cars'] != null && json['cars'] is List) {
      parsedCars = (json['cars'] as List)
          .map((e) => UserCarModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String? ?? json['fullName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? json['photo'] as String?,
      phone: parsedPhone,
      role: UserRole.fromString(roleStr),
      approved: json['approved'] as bool? ?? true,
      latitude: lat,
      longitude: lon,
      cars: parsedCars,
    );
  }
}

/// Complete login response containing tokens and user information.
class LoginResponseModel {
  final String accessToken;
  final String? refreshToken;

  const LoginResponseModel({
    required this.accessToken,
    this.refreshToken,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
    );
  }
}
