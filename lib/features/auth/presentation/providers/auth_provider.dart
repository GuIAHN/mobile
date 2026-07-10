import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state.dart';
import 'auth_notifier.dart';
export 'auth_notifier.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/upload_avatar_usecase.dart';

// ── Infrastructure ──────────────────────────────────────────────────────────

/// Provider for the remote auth datasource.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final client = ref.watch(dioClientProvider);
  return AuthRemoteDataSource(client);
});

/// Provider for the auth repository (contract → implementation).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

// ── Use Cases ──────────────────────────────────────────────────────────────

/// Provider for the login use case.
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

/// Provider for the register use case.
final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});


/// Provider for the update profile use case.
final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.watch(authRepositoryProvider));
});

/// Provider for the upload avatar use case.
final uploadAvatarUseCaseProvider = Provider<UploadAvatarUseCase>((ref) {
  return UploadAvatarUseCase(ref.watch(authRepositoryProvider));
});

/// Main auth state provider. Consumed by login and registration screens.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    loginUseCase: ref.watch(loginUseCaseProvider),
    registerUseCase: ref.watch(registerUseCaseProvider),
    updateProfileUseCase: ref.watch(updateProfileUseCaseProvider),
    uploadAvatarUseCase: ref.watch(uploadAvatarUseCaseProvider),
    authRepository: ref.watch(authRepositoryProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});
