import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/account_status.dart';
import 'package:guiautomotriz_mobile/core/services/socket_service.dart';
import 'package:guiautomotriz_mobile/core/storage/secure_storage.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/entities/user.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/register_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/upload_avatar_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/providers/auth_notifier.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/providers/auth_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSecureStorage extends Mock implements SecureStorage {}

class _MockSocketService extends Mock implements SocketService {}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier({
    required AuthRepository repository,
    required SecureStorage storage,
    required SocketService socketService,
    required User user,
  }) : super(
          loginUseCase: LoginUseCase(repository),
          registerUseCase: RegisterUseCase(repository),
          updateProfileUseCase: UpdateProfileUseCase(repository),
          uploadAvatarUseCase: UploadAvatarUseCase(repository),
          authRepository: repository,
          secureStorage: storage,
          socketService: socketService,
        ) {
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  @override
  Future<void> checkAuthStatus() async {}

  bool logoutCalled = false;

  @override
  Future<void> logout() async {
    logoutCalled = true;
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

void main() {
  late _MockAuthRepository repository;
  late _MockSecureStorage storage;
  late _MockSocketService socketService;

  setUp(() {
    repository = _MockAuthRepository();
    storage = _MockSecureStorage();
    socketService = _MockSocketService();
    when(() => socketService.onNotification)
        .thenAnswer((_) => const Stream.empty());
    when(() => socketService.disconnect()).thenReturn(null);
  });

  test('deletion success keeps an authenticated pending account in memory',
      () async {
    final purgeAt = DateTime.parse('2026-10-09T12:00:00.000Z');
    when(
      () => repository.requestAccountDeletion(password: 'current-password'),
    ).thenAnswer((_) async => Right(purgeAt));
    final notifier = _TestAuthNotifier(
      repository: repository,
      storage: storage,
      socketService: socketService,
      user: const User(
        id: 'user-1',
        email: 'driver@example.com',
        name: 'Driver',
      ),
    );
    addTearDown(notifier.dispose);

    final failure = await notifier.requestAccountDeletion(
      password: 'current-password',
    );

    expect(failure, isNull);
    expect(notifier.state.status, AuthStatus.authenticated);
    expect(notifier.state.user!.accountStatus, AccountStatus.pendingDeletion);
    expect(notifier.state.user!.deletionScheduledAt, purgeAt);
    verify(socketService.disconnect).called(1);
  });

  test('restore success clears the stale pending-deletion session', () async {
    when(repository.restoreAccount).thenAnswer((_) async => const Right(null));
    final notifier = _TestAuthNotifier(
      repository: repository,
      storage: storage,
      socketService: socketService,
      user: User(
        id: 'user-1',
        email: 'driver@example.com',
        name: 'Driver',
        accountStatus: AccountStatus.pendingDeletion,
        deletionScheduledAt: DateTime.parse('2026-10-09T12:00:00.000Z'),
      ),
    );
    addTearDown(notifier.dispose);

    final failure = await notifier.restoreAccount();

    expect(failure, isNull);
    expect(notifier.state.status, AuthStatus.unauthenticated);
    expect(notifier.state.user, isNull);
    verify(repository.restoreAccount).called(1);
    expect(notifier.logoutCalled, isTrue);
  });
}
