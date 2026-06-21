import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/store_category_config.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_provider.dart';
import 'auth_state.dart';

/// Notifier that manages the app's authentication state (login and registration).
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final AuthRepository _authRepository;
  final SecureStorage _secureStorage;

  AuthNotifier({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required AuthRepository authRepository,
    required SecureStorage secureStorage,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _authRepository = authRepository,
        _secureStorage = secureStorage,
        super(const AuthState.initial()) {
    checkAuthStatus();
  }

  /// Helper genérico para ejecutar llamadas de autenticación/registro.
  Future<void> _runAuthAction(Future<Either<Failure, User>> Function() action) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    final result = await action();
    result.fold(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: failure.message,
        );
      },
      (user) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
      },
    );
  }

  /// Checks the current authentication status and loads the user if token exists.
  Future<void> checkAuthStatus() async {
    final hasToken = await _secureStorage.hasToken();
    if (!hasToken) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }

    state = state.copyWith(status: AuthStatus.loading);
    final result = await _authRepository.getCurrentUser();
    result.fold(
      (failure) {
        _secureStorage.clearTokens();
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: failure.message,
        );
      },
      (user) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
      },
    );
  }

  /// Executes login with email and password.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _runAuthAction(() => _loginUseCase(LoginParams(email: email, password: password)));
  }

  /// Executes user registration.
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
  }) async {
    await _runAuthAction(
      () => _registerUseCase(
        RegisterParams(
          email: email,
          password: password,
          name: name,
          role: role,
          phone: phone,
        ),
      ),
    );
  }

  /// Executes mechanic or workshop registration.
  Future<void> registerMechanic({
    required String email,
    required String password,
    required String name,
    required String phone,
    required double latitude,
    required double longitude,
    required String description,
    required bool isWorkshop,
    required String identification,
    required List<String> specialtyIds,
  }) async {
    await _runAuthAction(
      () => _authRepository.registerMechanic(
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
      ),
    );
  }

  /// Executes store and catalog registration.
  Future<void> registerStore({
    required String email,
    required String password,
    required String name,
    required String phone,
    required double latitude,
    required double longitude,
    required String address,
    required String rif,
    required List<StoreCategoryConfig> catalog,
  }) async {
    await _runAuthAction(
      () => _authRepository.registerStore(
        email: email,
        password: password,
        name: name,
        phone: phone,
        latitude: latitude,
        longitude: longitude,
        address: address,
        rif: rif,
        catalog: catalog,
      ),
    );
  }

  /// Clears the current error.
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(
        status: AuthStatus.initial,
        errorMessage: null,
      );
    }
  }

  /// Logs out by clearing tokens from secure storage and resetting to initial state.
  Future<void> logout() async {
    await _secureStorage.clearTokens();
    state = const AuthState.initial();
  }
}

/// Main auth state provider. Consumed by login and registration screens.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    loginUseCase: ref.watch(loginUseCaseProvider),
    registerUseCase: ref.watch(registerUseCaseProvider),
    authRepository: ref.watch(authRepositoryProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});
