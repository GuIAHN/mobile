import 'package:dartz/dartz.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementación concreta del repositorio de autenticación.
/// Orquesta el datasource y el almacenamiento seguro de tokens.
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

      // Persistir tokens de forma segura.
      await secureStorage.saveToken(response.accessToken);
      if (response.refreshToken != null) {
        await secureStorage.saveRefreshToken(response.refreshToken!);
      }
      await secureStorage.saveUserId(response.user.id);

      return Right(response.user);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
  }) async {
    try {
      final response = await remoteDataSource.register(
        email: email,
        password: password,
        name: name,
        role: role,
        phone: phone,
      );

      // Persistir tokens de forma segura.
      await secureStorage.saveToken(response.accessToken);
      if (response.refreshToken != null) {
        await secureStorage.saveRefreshToken(response.refreshToken!);
      }
      await secureStorage.saveUserId(response.user.id);

      return Right(response.user);
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
      // Aunque falle el endpoint, siempre limpiamos tokens locales.
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
}
