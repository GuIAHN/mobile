import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/storage/secure_storage.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/register_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/upload_avatar_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/pages/register_mechanic_page.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/pages/register_store_page.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/pages/register_type_page.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/pages/register_user_page.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/pages/register_workshop_page.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/providers/auth_state.dart';
import 'package:guiautomotriz_mobile/features/vehicles/presentation/pages/register_vehicles_page.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSecureStorage extends Mock implements SecureStorage {}

class _ResponsiveAuthNotifier extends AuthNotifier {
  _ResponsiveAuthNotifier()
      : super(
          loginUseCase: LoginUseCase(_MockAuthRepository()),
          registerUseCase: RegisterUseCase(_MockAuthRepository()),
          updateProfileUseCase: UpdateProfileUseCase(_MockAuthRepository()),
          uploadAvatarUseCase: UploadAvatarUseCase(_MockAuthRepository()),
          authRepository: _MockAuthRepository(),
          secureStorage: _MockSecureStorage(),
        ) {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  @override
  Future<void> checkAuthStatus() async {}
}

typedef _PageFixture = ({String name, Widget page});
typedef _ViewportFixture = ({Size size, double textScale});

void main() {
  const pages = <_PageFixture>[
    (name: 'login', page: LoginPage()),
    (name: 'selector de perfil', page: RegisterTypePage()),
    (name: 'registro de usuario', page: RegisterUserPage()),
    (name: 'registro de mecánico', page: RegisterMechanicPage()),
    (name: 'registro de taller', page: RegisterWorkshopPage()),
    (name: 'registro de tienda', page: RegisterStorePage()),
    (name: 'registro de vehículos', page: RegisterVehiclesPage()),
  ];
  const viewports = <_ViewportFixture>[
    (size: Size(320, 568), textScale: 2),
    (size: Size(412, 915), textScale: 1.3),
    (size: Size(480, 1040), textScale: 1),
    (size: Size(915, 412), textScale: 1.3),
  ];

  testWidgets('all authentication and registration pages fit phone layouts',
      (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;

    for (final viewport in viewports) {
      tester.view.physicalSize = viewport.size;

      for (final fixture in pages) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith((ref) => _ResponsiveAuthNotifier()),
            ],
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: const EdgeInsets.only(top: 24, bottom: 24),
                  textScaler: TextScaler.linear(viewport.textScale),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: fixture.page,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final layoutException = tester.takeException();
        expect(
          layoutException,
          isNull,
          reason: '${fixture.name} falló en ${viewport.size} '
              'con texto ${viewport.textScale}x',
        );
        expect(find.byType(Scaffold), findsWidgets);

        final scrollables = find.byType(Scrollable);
        if (scrollables.evaluate().isNotEmpty) {
          await tester.drag(scrollables.first, const Offset(0, -600));
          await tester.pump();
          expect(
            tester.takeException(),
            isNull,
            reason: '${fixture.name} desbordó al desplazarse en '
                '${viewport.size}',
          );
        }

        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
  });
}
