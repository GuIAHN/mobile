import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/store_category_config.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/upload_avatar_usecase.dart';
import 'auth_state.dart';

/// Notifier that manages the app's authentication state (login and registration).
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final UploadAvatarUseCase _uploadAvatarUseCase;
  final AuthRepository _authRepository;
  final SecureStorage _secureStorage;

  AuthNotifier({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required UploadAvatarUseCase uploadAvatarUseCase,
    required AuthRepository authRepository,
    required SecureStorage secureStorage,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _updateProfileUseCase = updateProfileUseCase,
        _uploadAvatarUseCase = uploadAvatarUseCase,
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
        if (failure is UnauthorizedFailure) {
          _secureStorage.clearTokens();
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            errorMessage: failure.message,
          );
        } else {
          state = state.copyWith(
            status: AuthStatus.error,
            errorMessage: failure.message,
          );
        }
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

  /// Executes social login.
  Future<Either<Failure, User>> socialLogin({
    required String idToken,
    required String provider,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    final result = await _authRepository.socialLogin(
      idToken: idToken,
      provider: provider,
    );
    result.fold(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: failure is SocialNotRegisteredFailure ? null : failure.message,
        );
      },
      (user) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
      },
    );
    return result;
  }

  /// Executes user registration.
  Future<void> register({
    required String email,
    String? password,
    required String name,
    required String role,
    String? phone,
    String? idToken,
    String? provider,
  }) async {
    await _runAuthAction(
      () => _registerUseCase(
        RegisterParams(
          email: email,
          password: password,
          name: name,
          role: role,
          phone: phone,
          idToken: idToken,
          provider: provider,
        ),
      ),
    );
  }

  /// Executes mechanic or workshop registration.
  Future<void> registerMechanic({
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
        idToken: idToken,
        provider: provider,
      ),
    );
  }

  /// Executes store and catalog registration.
  Future<void> registerStore({
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
        idToken: idToken,
        provider: provider,
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

  /// Uploads the photo at [filePath] and updates the user's avatar.
  Future<void> updateProfilePhoto(String filePath) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final result = await _uploadAvatarUseCase(filePath);

    result.fold(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          errorMessage: failure.message,
        );
      },
      (updatedUser) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: updatedUser,
        );
      },
    );
  }

  /// Updates the current user's profile details.
  Future<void> updateProfile({
    String? name,
    String? phone,
    double? latitude,
    double? longitude,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    final result = await _updateProfileUseCase(
      name: name,
      phone: phone,
      latitude: latitude,
      longitude: longitude,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          errorMessage: failure.message,
        );
      },
      (updatedUser) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: updatedUser,
        );
      },
    );
  }
}
