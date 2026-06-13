import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

/// Contrato del repositorio de autenticación (dominio puro).
/// La implementación vive en la capa data.
abstract class AuthRepository {
  /// Inicia sesión con [email] y [password].
  /// Retorna el [User] autenticado o un [Failure].
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  /// Registra un nuevo usuario con su respectivo rol.
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
  });

  /// Cierra la sesión actual y limpia los tokens almacenados.
  Future<Either<Failure, void>> logout();

  /// Retorna el usuario actualmente autenticado (por token guardado).
  Future<Either<Failure, User>> getCurrentUser();
}
