import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Parámetros del caso de uso de registro.
class RegisterParams extends Equatable {
  final String email;
  final String password;
  final String name;
  final String role;
  final String? phone;

  const RegisterParams({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    this.phone,
  });

  @override
  List<Object?> get props => [email, password, name, role, phone];
}

/// Caso de uso: Registrar un nuevo usuario.
class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, User>> call(RegisterParams params) {
    return repository.register(
      email: params.email,
      password: params.password,
      name: params.name,
      role: params.role,
      phone: params.phone,
    );
  }
}
