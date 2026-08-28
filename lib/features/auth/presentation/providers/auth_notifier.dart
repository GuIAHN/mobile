import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/network/token_refresh_coordinator.dart';
import '../../../../features/notifications/services/push_notifications_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/store_coverage_config.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/upload_avatar_usecase.dart';
import '../../../vehicles/domain/entities/user_car.dart';
import 'auth_state.dart';

/// Notifier that manages the app's authentication state (login and registration).
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final UploadAvatarUseCase _uploadAvatarUseCase;
  final AuthRepository _authRepository;
  final SecureStorage _secureStorage;
  final SocketService? _socketService;
  final TokenRefreshCoordinator? _tokenRefreshCoordinator;
  StreamSubscription<Map<String, dynamic>>? _notificationSub;
  StreamSubscription<void>? _sessionInvalidatedSub;
  Future<void>? _deviceTokenSyncInFlight;

  static const _accountStatusTipos = {'user.approved', 'user.rejected'};

  AuthNotifier({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required UploadAvatarUseCase uploadAvatarUseCase,
    required AuthRepository authRepository,
    required SecureStorage secureStorage,
    SocketService? socketService,
    TokenRefreshCoordinator? tokenRefreshCoordinator,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _updateProfileUseCase = updateProfileUseCase,
        _uploadAvatarUseCase = uploadAvatarUseCase,
        _authRepository = authRepository,
        _secureStorage = secureStorage,
        _socketService = socketService,
        _tokenRefreshCoordinator = tokenRefreshCoordinator,
        super(const AuthState.initial()) {
    checkAuthStatus();
    _notificationSub = _socketService?.onNotification.listen((data) {
      if (_accountStatusTipos.contains(data['tipo'])) {
        refreshUser();
      }
    });
    _sessionInvalidatedSub =
        tokenRefreshCoordinator?.onSessionInvalidated.listen((_) {
      _socketService?.disconnect();
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        user: null,
        errorMessage: 'Tu sesión expiró. Inicia sesión nuevamente.',
      );
    });
  }

  /// Refetches the current user silently (no loading state) to reflect
  /// server-side changes such as account approval/rejection in real time.
  Future<void> refreshUser() async {
    if (state.status != AuthStatus.authenticated) return;
    final result = await _authRepository.getCurrentUser();
    result.fold(
      (failure) {
        // Ignore transient failures; keep the cached user as-is.
      },
      (user) {
        if (state.user != user) {
          state = state.copyWith(user: user);
        }
      },
    );
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    _sessionInvalidatedSub?.cancel();
    super.dispose();
  }

  /// Helper genérico para ejecutar llamadas de autenticación/registro.
  Future<void> _runAuthAction(
      Future<Either<Failure, User>> Function() action) async {
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
        _tokenRefreshCoordinator?.markSessionActive();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
        _syncDeviceToken();
      },
    );
  }

  /// Runs a provider application without turning it into an authenticated
  /// session. Provider accounts must be reviewed before entering the app.
  Future<void> _runProviderRegistration(
      Future<Either<Failure, User>> Function() action) async {
    state = const AuthState(status: AuthStatus.loading);
    final result = await action();
    result.fold(
      (failure) {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: failure.message,
        );
      },
      (user) {
        state = AuthState(
          status: AuthStatus.providerRegistrationSucceeded,
          user: user,
        );
      },
    );
  }

  /// Syncs the device token to the backend for push notifications
  Future<void> _syncDeviceToken() {
    final inFlight = _deviceTokenSyncInFlight;
    if (inFlight != null) return inFlight;

    late final Future<void> operation;
    operation = _performDeviceTokenSync().whenComplete(() {
      if (identical(_deviceTokenSyncInFlight, operation)) {
        _deviceTokenSyncInFlight = null;
      }
    });
    _deviceTokenSyncInFlight = operation;
    return operation;
  }

  Future<void> _performDeviceTokenSync() async {
    try {
      final token = await PushNotificationsService.getToken();
      final userId = state.user?.id;
      if (token == null || userId == null) return;
      if (await _secureStorage.isDeviceTokenSynced(
        userId: userId,
        token: token,
      )) {
        return;
      }

      final result = await _authRepository.registerDeviceToken(
        token,
        deviceOs: kIsWeb ? 'web' : defaultTargetPlatform.name,
      );
      await result.fold(
        (_) async {},
        (_) => _secureStorage.markDeviceTokenSynced(
          userId: userId,
          token: token,
        ),
      );
    } catch (_) {
      // Ignore errors for token sync
    }
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
        _tokenRefreshCoordinator?.markSessionActive();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
        _syncDeviceToken();
      },
    );
  }

  /// Executes login with email and password.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _runAuthAction(
        () => _loginUseCase(LoginParams(email: email, password: password)));
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
          errorMessage:
              failure is SocialNotRegisteredFailure ? null : failure.message,
        );
      },
      (user) {
        _tokenRefreshCoordinator?.markSessionActive();
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
        _syncDeviceToken();
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
    required bool acceptedTerms,
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
          acceptedTerms: acceptedTerms,
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
    required bool acceptedTerms,
    String? idPhotoPath,
    String? rifPhotoPath,
  }) async {
    await _runProviderRegistration(
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
        acceptedTerms: acceptedTerms,
        idPhotoPath: idPhotoPath,
        rifPhotoPath: rifPhotoPath,
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
    required StoreCoverageConfig coverage,
    required bool hasDelivery,
    String? idToken,
    String? provider,
    required bool acceptedTerms,
    required String rifPhotoPath,
  }) async {
    await _runProviderRegistration(
      () => _authRepository.registerStore(
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

  /// Leaves the provider registration confirmation ready for a fresh login.
  void finishProviderRegistration() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Logs out by calling repository logout (invalidating server session & clearing secure tokens)
  /// and updating authentication state to unauthenticated.
  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    // Cortar primero la sala personal y todas las conversaciones de la cuenta
    // saliente. No mantener el socket vivo mientras el logout HTTP responde.
    _socketService?.disconnect();
    // If login/startup is still registering this device, let it finish before
    // removing the token so a late upsert cannot recreate it after logout.
    await _deviceTokenSyncInFlight;
    try {
      final token = await PushNotificationsService.getToken();
      if (token != null) {
        await _authRepository.removeDeviceToken(token);
      }
    } catch (e) {
      // Ignore errors
    }
    // Invalidar también en FCM: si el backend no estuvo disponible, el token
    // anterior deja de ser un destino válido de todas formas. El siguiente
    // login obtiene y registra uno nuevo para su propio userId.
    await PushNotificationsService.deleteToken();
    await _authRepository.logout();
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      user: null,
      errorMessage: null,
    );
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
          user: _mergeUpdatedProfile(
            updatedUser,
            latitude: latitude,
            longitude: longitude,
          ),
        );
      },
    );
  }

  /// Updates the geographic point used by place-based provider profiles.
  ///
  /// This operation deliberately keeps its loading and failure state local to
  /// the location card so editing a map point does not block the whole profile.
  /// The endpoint response currently omits the PostGIS location, therefore the
  /// submitted coordinates are merged back into the authenticated user cache.
  Future<Failure?> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    final result = await _updateProfileUseCase(
      latitude: latitude,
      longitude: longitude,
    );

    return result.fold(
      (failure) => failure,
      (updatedUser) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: _mergeUpdatedProfile(
            updatedUser,
            latitude: latitude,
            longitude: longitude,
          ),
          errorMessage: null,
        );
        return null;
      },
    );
  }

  User _mergeUpdatedProfile(
    User updatedUser, {
    double? latitude,
    double? longitude,
  }) {
    final cachedUser = state.user;
    return updatedUser.copyWith(
      latitude: latitude ?? updatedUser.latitude ?? cachedUser?.latitude,
      longitude: longitude ?? updatedUser.longitude ?? cachedUser?.longitude,
      cars: updatedUser.cars ?? cachedUser?.cars,
    );
  }

  /// Adds a new car to the cached user profile to maintain sync without refetching.
  void addUserCar(UserCar car) {
    if (state.user != null) {
      final updatedCars = List<UserCar>.from(state.user!.cars ?? [])..add(car);
      state = state.copyWith(user: state.user!.copyWith(cars: updatedCars));
    }
  }

  /// Removes a car from the cached user profile.
  void removeUserCar(String carId) {
    if (state.user != null && state.user!.cars != null) {
      final updatedCars =
          state.user!.cars!.where((c) => c.id != carId).toList();
      state = state.copyWith(user: state.user!.copyWith(cars: updatedCars));
    }
  }
}
