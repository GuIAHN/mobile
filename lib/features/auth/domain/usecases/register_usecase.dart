import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Parámetros del caso de uso de registro.
class RegisterParams extends Equatable {
  final String email;
  final String? password;
  final String name;
  final String role;
  final String? phone;
  final String? idToken;
  final String? provider;
  final bool acceptedTerms;

  const RegisterParams({
    required this.email,
    this.password,
    required this.name,
    required this.role,
    this.phone,
    this.idToken,
    this.provider,
    required this.acceptedTerms,
  });

  @override
  List<Object?> get props => [
        email,
        password,
        name,
        role,
        phone,
        idToken,
        provider,
        acceptedTerms,
      ];
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
      idToken: params.idToken,
      provider: params.provider,
      acceptedTerms: params.acceptedTerms,
    );
  }
}
