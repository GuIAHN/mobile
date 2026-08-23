import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../entities/store_category_config.dart';

/// Authentication repository contract (pure domain).
/// The implementation resides in the data layer.
abstract class AuthRepository {
  /// Logs in with [email] and [password].
  /// Returns the authenticated [User] or a [Failure].
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  /// Logs in using social credentials (Google or Apple).
  Future<Either<Failure, User>> socialLogin({
    required String idToken,
    required String provider,
  });

  /// Registers a new user with their respective role.
  Future<Either<Failure, User>> register({
    required String email,
    String? password,
    required String name,
    required String role,
    String? phone,
    String? idToken,
    String? provider,
    required bool acceptedTerms,
  });

  /// Registers a mechanic or workshop.
  Future<Either<Failure, User>> registerMechanic({
    required String email,
    String? password,
    required String name,
    required String phone,
    required double latitude,
    required double longitude,
    required String description,
    required bool isWorkshop,
    required String identification,
    required List<String> specialtyIds,
    String? idToken,
    String? provider,
    required bool acceptedTerms,
    String? idPhotoPath,
    String? rifPhotoPath,
    String? mercantilRegistryPath,
  });

  /// Registers a store and configures its initial catalog.
  Future<Either<Failure, User>> registerStore({
    required String email,
    String? password,
    required String name,
    required String phone,
    required double latitude,
    required double longitude,
    required String address,
    required String rif,
    required List<StoreCategoryConfig> catalog,
    required bool hasDelivery,
    String? idToken,
    String? provider,
    required bool acceptedTerms,
    required String rifPhotoPath,
    required String mercantilRegistryPath,
  });

  /// Closes the current session and clears stored tokens.
  Future<Either<Failure, void>> logout();

  /// Requests a six-digit password reset code for [email].
  Future<Either<Failure, String>> forgotPassword({required String email});

  /// Replaces the forgotten password after validating the emailed [code].
  Future<Either<Failure, String>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  /// Returns the currently authenticated user (by stored token).
  Future<Either<Failure, User>> getCurrentUser();

  /// Uploads an avatar image file to the server and returns the updated user profile.
  Future<Either<Failure, User>> uploadAvatar(String filePath);

  /// Updates the current user's profile details.
  Future<Either<Failure, User>> updateProfile({
    String? name,
    String? photo,
    String? phone,
    double? latitude,
    double? longitude,
  });

  /// Changes the current user's password. Requires [currentPassword] to be
  /// verified server-side before [newPassword] is set.
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Registers a device token for push notifications
  Future<Either<Failure, void>> registerDeviceToken(String token,
      {String? deviceOs});

  /// Removes a device token for push notifications
  Future<Either<Failure, void>> removeDeviceToken(String token);
}
