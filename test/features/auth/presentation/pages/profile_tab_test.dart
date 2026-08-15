import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/user_role.dart';
import 'package:guiautomotriz_mobile/core/storage/secure_storage.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/entities/user.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/register_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/upload_avatar_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/pages/profile_tab.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/providers/auth_state.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/widgets/profile_header.dart';
import 'package:guiautomotriz_mobile/features/vehicles/presentation/providers/vehicle_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSecureStorage extends Mock implements SecureStorage {}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(User user)
      : super(
          loginUseCase: LoginUseCase(_MockAuthRepository()),
          registerUseCase: RegisterUseCase(_MockAuthRepository()),
          updateProfileUseCase: UpdateProfileUseCase(_MockAuthRepository()),
          uploadAvatarUseCase: UploadAvatarUseCase(_MockAuthRepository()),
          authRepository: _MockAuthRepository(),
          secureStorage: _MockSecureStorage(),
        ) {
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  @override
  Future<void> checkAuthStatus() async {}
}

void main() {
  testWidgets('keeps profile content below the iPhone camera safe area',
      (tester) async {
    const topSafeArea = 59.0;
    const user = User(
      id: 'consumer-1',
      email: 'consumer@gmail.com',
      name: 'Usuario Consumidor',
      phone: '04121111111',
      role: UserRole.consumer,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _TestAuthNotifier(user)),
          userCarsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(390, 844),
              padding: EdgeInsets.only(top: topSafeArea, bottom: 34),
            ),
            child: Scaffold(body: ProfileTab()),
          ),
        ),
      ),
    );
    await tester.pump();

    final headerTop = tester.getTopLeft(find.byType(ProfileHeader)).dy;
    expect(headerTop, greaterThanOrEqualTo(topSafeArea + 24));
    expect(tester.takeException(), isNull);
  });
}
