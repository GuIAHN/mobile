import 'package:dartz/dartz.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/store_category_config.dart';
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
  }) async {
    try {
      // 1. Create the user in the backend.
      final registeredUser = await remoteDataSource.register(
        email: email,
        password: password,
        name: name,
        role: role,
        idToken: idToken,
        provider: provider,
      );

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

      // Save obtained tokens securely.
      await secureStorage.saveToken(loginResponse.accessToken);
      if (loginResponse.refreshToken != null) {
        await secureStorage.saveRefreshToken(loginResponse.refreshToken!);
      }
      await secureStorage.saveUserId(registeredUser.id);

      // 3. Register the phone number in a separate endpoint if specified.
      if (phone != null && phone.trim().isNotEmpty) {
        await remoteDataSource.updatePhone(phone);
      }

      // 4. Retrieve the updated full profile from the API.
      final finalUser = await remoteDataSource.getCurrentUser();

      return Right(finalUser);
    } catch (e) {
      return Left(ErrorMapper.map(e));
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
      );

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

      await secureStorage.saveToken(loginResponse.accessToken);
      if (loginResponse.refreshToken != null) {
        await secureStorage.saveRefreshToken(loginResponse.refreshToken!);
      }
      await secureStorage.saveUserId(registeredUser.id);

      final finalUser = await remoteDataSource.getCurrentUser();
      return Right(finalUser);
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
    required List<StoreCategoryConfig> catalog,
    String? idToken,
    String? provider,
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
        catalog: catalog,
        idToken: idToken,
        provider: provider,
      );

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

      await secureStorage.saveToken(loginResponse.accessToken);
      if (loginResponse.refreshToken != null) {
        await secureStorage.saveRefreshToken(loginResponse.refreshToken!);
      }
      await secureStorage.saveUserId(registeredUser.id);

      final finalUser = await remoteDataSource.getCurrentUser();
      return Right(finalUser);
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
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, String>> uploadImage(String filePath) async {
    try {
      final url = await remoteDataSource.uploadImage(filePath);
      return Right(url);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({String? name, String? photo}) async {
    try {
      final user = await remoteDataSource.updateProfile(name: name, photo: photo);
      return Right(user);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }
}

