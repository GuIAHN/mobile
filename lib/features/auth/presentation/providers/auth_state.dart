import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

/// Estado posible para la pantalla de login.
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  providerRegistrationSucceeded,
  error,
}

/// Estado inmutable de la UI de autenticación.
class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  const AuthState.initial() : this();

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    Object? errorMessage = _sentinel,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isProviderRegistrationSucceeded =>
      status == AuthStatus.providerRegistrationSucceeded;
  @override
  List<Object?> get props => [status, user, errorMessage];
}

const _sentinel = Object();
