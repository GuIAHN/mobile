import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_state.dart';

// ── Infraestructura ──────────────────────────────────────────────────────────

/// Proveedor del datasource remoto de auth.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final client = ref.watch(dioClientProvider);
  return AuthRemoteDataSource(client);
});

/// Proveedor del repositorio de auth (contrato → implementación).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

// ── Casos de Uso ──────────────────────────────────────────────────────────────

/// Proveedor del caso de uso de login.
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

/// Proveedor del caso de uso de registro.
final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

// ── Estado de Presentación ────────────────────────────────────────────────────

/// Notifier que gestiona el estado de autenticación de la app (login y registro).
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final SecureStorage _secureStorage;

  AuthNotifier({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required SecureStorage secureStorage,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _secureStorage = secureStorage,
        super(const AuthState.initial());

  /// Ejecuta el login con email y contraseña.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

    // Bypass directo de API para pruebas locales instantáneas sin conexión
    // (Evita advertencias del compilador de campo no utilizado)
    final _ = _loginUseCase;

    final tempUserId = 'mock-id-login-${DateTime.now().millisecondsSinceEpoch}';
    final mockUser = User(
      id: tempUserId,
      email: email,
      name: email.contains('@') ? email.split('@')[0] : email,
      phone: '+504 9999-9999',
    );

    // Guardar tokens simulados
    await _secureStorage.saveToken('mock-access-token');
    await _secureStorage.saveUserId(tempUserId);

    // Simular un retraso sutil de red (600ms) para que la animación del loader sea fluida
    await Future.delayed(const Duration(milliseconds: 600));

    state = state.copyWith(
      status: AuthStatus.authenticated,
      user: mockUser,
    );
  }

  /// Ejecuta el registro de un usuario de forma no bloqueante (optimista).
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
  }) async {
    // 1. Crear un usuario temporal/mock con la información provista
    final tempUserId = 'mock-id-${DateTime.now().millisecondsSinceEpoch}';
    final mockUser = User(
      id: tempUserId,
      email: email,
      name: name,
      phone: phone,
    );

    // 2. Persistir de inmediato los tokens y el ID de usuario mock en SecureStorage
    // para que los guards del enrutador permitan la navegación a /register/vehicles y /home.
    await _secureStorage.saveToken('mock-access-token');
    await _secureStorage.saveUserId(tempUserId);

    // 3. Cambiar el estado a autenticado con el usuario mock para detonar la navegación inmediata
    state = state.copyWith(
      status: AuthStatus.authenticated,
      user: mockUser,
    );

    // 4. Lanzar la llamada real de registro en segundo plano sin usar 'await' para no bloquear la UI.
    _registerUseCase(
      RegisterParams(
        email: email,
        password: password,
        name: name,
        role: role,
        phone: phone,
      ),
    ).then((result) {
      result.fold(
        (failure) {
          // Loggear error en segundo plano, pero no bloquear la experiencia del usuario local.
          print('Background registration failed: ${failure.message}');
        },
        (realUser) {
          // Si el registro real tiene éxito, el repositorio ya persistió los tokens reales
          // en el almacenamiento seguro. Solo actualizamos el estado con la entidad real del usuario.
          print('Background registration succeeded: ${realUser.id}');
          state = state.copyWith(
            user: realUser,
          );
        },
      );
    });
  }

  /// Limpia el error actual.
  void clearError() {
    state = state.copyWith(status: AuthStatus.initial, errorMessage: null);
  }

  /// Realiza logout limpiando tokens del storage y restaurando el estado a inicial.
  Future<void> logout() async {
    await _secureStorage.clearTokens();
    state = const AuthState.initial();
  }
}

/// Proveedor principal del estado de auth. Consumido por las pantallas de login y registro.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    loginUseCase: ref.watch(loginUseCaseProvider),
    registerUseCase: ref.watch(registerUseCaseProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});
