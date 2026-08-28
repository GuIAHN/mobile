import 'package:dartz/dartz.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/store_coverage_config.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

/// Concrete implementation of the authentication repository.
/// Orchestrates the datasource and secure token storage.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorage secureStorage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
  });

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await remoteDataSource.login(
        email: email,
        password: password,
      );

      // Save tokens securely.
      await secureStorage.saveToken(response.accessToken);
      if (response.refreshToken != null) {
        await secureStorage.saveRefreshToken(response.refreshToken!);
      }

      // Fetch the actual user profile from the API.
      final user = await remoteDataSource.getCurrentUser();
      await secureStorage.saveUserId(user.id);

      return Right(user);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, User>> socialLogin({
    required String idToken,
    required String provider,
  }) async {
    try {
      final response = await remoteDataSource.socialLogin(
        idToken: idToken,
        provider: provider,
      );

      // Save tokens securely.
      await secureStorage.saveToken(response.accessToken);
      if (response.refreshToken != null) {
        await secureStorage.saveRefreshToken(response.refreshToken!);
      }

      // Fetch the actual user profile from the API.
      final user = await remoteDataSource.getCurrentUser();
      await secureStorage.saveUserId(user.id);

      return Right(user);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, User>> register({
    required String email,
    String? password,
    required String name,
    required String role,
    String? phone,
    String? idToken,
    String? provider,
    required bool acceptedTerms,
  }) async {
    User? registeredUser;
    try {
      // 1. Create the user in the backend.
      try {
        registeredUser = await remoteDataSource.register(
          email: email,
          password: password,
          name: name,
          role: role,
          idToken: idToken,
          provider: provider,
          acceptedTerms: acceptedTerms,
        );
      } catch (registrationError) {
        // A previous social attempt may have created the account before the
        // follow-up login/profile request failed. Retrying social login makes
        // that partial success recoverable instead of trapping the user in an
        // "already registered" loop.
        if (idToken == null || provider == null) rethrow;

        try {
          final loginResponse = await remoteDataSource.socialLogin(
            idToken: idToken,
            provider: provider,
          );
          await _persistSession(loginResponse);
          if (phone != null && phone.trim().isNotEmpty) {
            try {
              await remoteDataSource.updateProfile(phone: phone);
            } catch (_) {
              // Recovery should still complete when optional enrichment fails.
            }
          }
          final recoveredUser = await remoteDataSource.getCurrentUser();
          await secureStorage.saveUserId(recoveredUser.id);
          return Right(recoveredUser);
        } catch (_) {
          throw registrationError;
        }
      }

      // 2. Log in automatically to obtain tokens for the active session.
      final LoginResponseModel loginResponse;
      if (idToken != null && provider != null) {
        loginResponse = await remoteDataSource.socialLogin(
          idToken: idToken,
          provider: provider,
        );
      } else {
        loginResponse = await remoteDataSource.login(
          email: email,
          password: password!,
        );
      }

      // Save obtained tokens securely. From this point onward registration is
      // complete; optional profile enrichment must not turn it into a failure.
      await _persistSession(loginResponse);
      await secureStorage.saveUserId(registeredUser.id);

      // 3. Register the phone number if specified.
      if (phone != null && phone.trim().isNotEmpty) {
        try {
          await remoteDataSource.updateProfile(phone: phone);
        } catch (_) {
          // The account and session already exist. The phone can be completed
          // later from the profile without forcing the user to register again.
        }
      }

      // 4. Retrieve the updated full profile from the API.
      User finalUser = registeredUser;
      try {
        finalUser = await remoteDataSource.getCurrentUser();
      } catch (_) {
        // Keep the valid registration response when profile refresh is
        // temporarily unavailable.
      }

      return Right(finalUser);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  Future<void> _persistSession(LoginResponseModel loginResponse) async {
    await secureStorage.saveToken(loginResponse.accessToken);
    if (loginResponse.refreshToken != null) {
      await secureStorage.saveRefreshToken(loginResponse.refreshToken!);
    }
  }

  @override
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
  }) async {
    try {
      final registeredUser = await remoteDataSource.registerMechanic(
        email: email,
        password: password,
        name: name,
        phone: phone,
        latitude: latitude,
        longitude: longitude,
        description: description,
        isWorkshop: isWorkshop,
        identification: identification,
        specialtyIds: specialtyIds,
        idToken: idToken,
        provider: provider,
        acceptedTerms: acceptedTerms,
        idPhotoPath: idPhotoPath,
        rifPhotoPath: rifPhotoPath,
      );

      return Right(registeredUser);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, User>> registerStore({
    required String email,
    String? password,
    required String name,
    required String phone,
    required double latitude,
    required double longitude,
    required String address,
    required String rif,
    required StoreCoverageConfig coverage,
    required bool hasDelivery,
    String? idToken,
    String? provider,
    required bool acceptedTerms,
    required String rifPhotoPath,
  }) async {
    try {
      final registeredUser = await remoteDataSource.registerStore(
        email: email,
        password: password,
        name: name,
        phone: phone,
        latitude: latitude,
        longitude: longitude,
        address: address,
        rif: rif,
        coverage: coverage,
        hasDelivery: hasDelivery,
        idToken: idToken,
        provider: provider,
        acceptedTerms: acceptedTerms,
        rifPhotoPath: rifPhotoPath,
      );

      // Stores also require approval, so registration success is intentionally
      // not an authenticated session.
      return Right(registeredUser);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      await secureStorage.clearTokens();
      return const Right(null);
    } catch (e) {
      // Even if the endpoint fails, always clear local tokens.
      await secureStorage.clearTokens();
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, String>> forgotPassword({
    required String email,
  }) async {
    try {
      return Right(await remoteDataSource.forgotPassword(email: email));
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, String>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      return Right(
        await remoteDataSource.resetPassword(
          email: email,
          code: code,
          newPassword: newPassword,
        ),
      );
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, User>> uploadAvatar(String filePath) async {
    try {
      final user = await remoteDataSource.uploadAvatar(filePath);
      return Right(user);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    String? name,
    String? photo,
    String? phone,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final user = await remoteDataSource.updateProfile(
        name: name,
        photo: photo,
        phone: phone,
        latitude: latitude,
        longitude: longitude,
      );
      return Right(user);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await remoteDataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Right(null);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, void>> registerDeviceToken(String token,
      {String? deviceOs}) async {
    try {
      await remoteDataSource.registerDeviceToken(token, deviceOs: deviceOs);
      return const Right(null);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, void>> removeDeviceToken(String token) async {
    try {
      await remoteDataSource.removeDeviceToken(token);
      return const Right(null);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }
}
