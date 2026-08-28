import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/user_role.dart';
import 'package:guiautomotriz_mobile/core/router/route_names.dart';
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
import 'package:guiautomotriz_mobile/features/catalog/domain/entities/specialty.dart';
import 'package:guiautomotriz_mobile/features/provider_profile/domain/entities/store_catalog.dart';
import 'package:guiautomotriz_mobile/features/provider_profile/presentation/providers/provider_profile_providers.dart';
import 'package:guiautomotriz_mobile/features/provider_profile/presentation/widgets/provider_location_card.dart';
import 'package:guiautomotriz_mobile/features/provider_profile/presentation/widgets/provider_specialties_card.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/entities/pending_review.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/providers/reviews_providers.dart';
import 'package:guiautomotriz_mobile/features/vehicles/domain/entities/user_car.dart';
import 'package:guiautomotriz_mobile/features/vehicles/presentation/providers/vehicle_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSecureStorage extends Mock implements SecureStorage {}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(User user)
      : this.withState(
          AuthState(status: AuthStatus.authenticated, user: user),
        );

  _TestAuthNotifier.withState(AuthState initialState)
      : super(
          loginUseCase: LoginUseCase(_MockAuthRepository()),
          registerUseCase: RegisterUseCase(_MockAuthRepository()),
          updateProfileUseCase: UpdateProfileUseCase(_MockAuthRepository()),
          uploadAvatarUseCase: UploadAvatarUseCase(_MockAuthRepository()),
          authRepository: _MockAuthRepository(),
          secureStorage: _MockSecureStorage(),
        ) {
    state = initialState;
  }

  @override
  Future<void> checkAuthStatus() async {}
}

void main() {
  testWidgets(
      'shows and exposes description editing for mechanics and workshops',
      (tester) async {
    const description = 'Especialista en diagnóstico electrónico y frenos.';
    const user = User(
      id: 'mechanic-1',
      email: 'mechanic@example.com',
      name: 'Carlos Mecánico',
      phone: '04121111111',
      description: description,
      role: UserRole.mechanic,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _TestAuthNotifier(user)),
          providerSpecialtiesProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileTab())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('provider-description-panel')), findsOneWidget);
    expect(find.text(description), findsOneWidget);

    await tester.tap(find.byKey(const Key('edit-profile')));
    await tester.pumpAndSettle();

    final field = tester.widget<TextFormField>(
      find.byKey(const Key('provider-description-field')),
    );
    expect(field.controller?.text, description);
    final editable = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('provider-description-field')),
        matching: find.byType(EditableText),
      ),
    );
    expect(editable.maxLines, 7);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not show provider description controls for consumers',
      (tester) async {
    const user = User(
      id: 'consumer-description-1',
      email: 'consumer@example.com',
      name: 'Usuario Consumidor',
      role: UserRole.consumer,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _TestAuthNotifier(user)),
          userCarsProvider.overrideWith((ref) async => const []),
          pendingReviewsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileTab())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('provider-description-panel')), findsNothing);
    await tester.tap(find.byKey(const Key('edit-profile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('provider-description-field')), findsNothing);
  });

  testWidgets('does not repeat the profile label inside the profile tab',
      (tester) async {
    const user = User(
      id: 'consumer-1',
      email: 'consumer@gmail.com',
      name: 'Usuario Consumidor',
      role: UserRole.consumer,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _TestAuthNotifier(user)),
          userCarsProvider.overrideWith((ref) async => const []),
          pendingReviewsProvider.overrideWith(
            (ref) async => const [
              PendingReview(
                targetId: 'store-user-1',
                providerProfileId: 'store-1',
                providerName: 'Elio’s Shop',
                conversationId: 'conversation-1',
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileTab())),
      ),
    );
    await tester.pump();

    expect(find.text('Perfil'), findsNothing);
    expect(find.byType(ProfileHeader), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows explicit loading and recoverable error states',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            (ref) => _TestAuthNotifier.withState(
              const AuthState(status: AuthStatus.loading),
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileTab())),
      ),
    );

    expect(find.text('Cargando tu perfil…'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            (ref) => _TestAuthNotifier.withState(
              const AuthState(
                status: AuthStatus.error,
                errorMessage: 'No se pudo cargar el perfil.',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileTab())),
      ),
    );

    expect(find.text('No se pudo cargar el perfil.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
          pendingReviewsProvider.overrideWith((ref) async => const []),
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

  testWidgets('pending reviews matches the change-password card height',
      (tester) async {
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
          pendingReviewsProvider.overrideWith(
            (ref) async => const [
              PendingReview(
                targetId: 'store-user-1',
                providerProfileId: 'store-1',
                providerName: 'Elio’s Shop',
                conversationId: 'conversation-1',
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileTab())),
      ),
    );
    await tester.pump();

    final securitySize = tester.getSize(find.byKey(
      const Key('open-change-password'),
    ));
    final pendingSize = tester.getSize(find.byKey(
      const Key('open-pending-reviews'),
    ));

    expect(pendingSize.height, securitySize.height);
    expect(pendingSize.width, securitySize.width);
    expect(find.byKey(const Key('open-received-reviews')), findsNothing);
    expect(find.byKey(const Key('profile-action-badge')), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('orders identity, contact information and account shortcuts',
      (tester) async {
    const user = User(
      id: 'consumer-1',
      email: 'consumer@gmail.com',
      name: 'Usuario Consumidor',
      phone: '+504 9999 1111',
      role: UserRole.consumer,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _TestAuthNotifier(user)),
          userCarsProvider.overrideWith((ref) async => const []),
          pendingReviewsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileTab())),
      ),
    );
    await tester.pumpAndSettle();

    final headerRect = tester.getRect(find.byType(ProfileHeader));
    final avatarRect = tester.getRect(
      find.byKey(const Key('change-profile-photo')),
    );
    expect(avatarRect.center.dx, closeTo(headerRect.center.dx, 1));

    final nameTop = tester.getTopLeft(find.text('Usuario Consumidor')).dy;
    final contactTop =
        tester.getTopLeft(find.text('INFORMACIÓN DE CONTACTO')).dy;
    final accountTop = tester.getTopLeft(find.text('MI CUENTA')).dy;

    expect(nameTop, lessThan(contactTop));
    expect(contactTop, lessThan(accountTop));
    expect(find.text('+504 9999 1111'), findsOneWidget);
    expect(find.text('consumer@gmail.com'), findsOneWidget);
    expect(find.text('CONSUMIDOR'), findsOneWidget);
  });

  testWidgets('supports small and large phones with scaled profile text',
      (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;

    const user = User(
      id: 'consumer-1',
      email: 'usuario.con.correo.extenso@example.com',
      name: 'Usuario con nombre completo extenso',
      phone: '+50499991111',
      role: UserRole.consumer,
    );

    for (final size in const [Size(320, 568), Size(430, 932)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _TestAuthNotifier(user)),
            userCarsProvider.overrideWith((ref) async => const []),
            pendingReviewsProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: const Scaffold(body: ProfileTab()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(const Key('edit-profile'))).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.byKey(const Key('change-profile-photo'))).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.byKey(const Key('open-change-password'))).height,
        greaterThanOrEqualTo(48),
      );

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -1000),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('adapts profile cards and garage across Android phone dimensions',
      (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;

    const user = User(
      id: 'consumer-android',
      email: 'consumer.pixel@example.com',
      name: 'Usuario Android',
      phone: '+504 9999 1111',
      role: UserRole.consumer,
    );
    const car = UserCar(
      id: 'android-car',
      brand: 'BMW',
      model: 'X3',
      year: 2025,
      vehicleType: 'SUV',
    );

    const deviceSizes = <Size>[
      Size(360, 640),
      Size(412, 915),
      Size(430, 932),
      Size(480, 1040),
      Size(915, 412),
    ];

    for (final size in deviceSizes) {
      tester.view.physicalSize = size;
      final textScale = size.width == 360 ? 2.0 : 1.3;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _TestAuthNotifier(user)),
            userCarsProvider.overrideWith((ref) async => const [car]),
            pendingReviewsProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(top: 24, bottom: 24),
                textScaler: TextScaler.linear(textScale),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: const Scaffold(body: ProfileTab()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final layoutException = tester.takeException();
      expect(layoutException, isNull, reason: 'Falló en $size');

      final contentRect = tester.getRect(
        find.byKey(const Key('profile-content')),
      );
      final carRect = tester.getRect(
        find.byKey(const ValueKey('profile-garage-car-android-car')),
      );
      expect(contentRect.left, greaterThanOrEqualTo(0));
      expect(contentRect.right, lessThanOrEqualTo(size.width));
      expect(carRect.left, greaterThanOrEqualTo(contentRect.left));
      expect(carRect.right, lessThanOrEqualTo(contentRect.right));

      if (size.width < 368) {
        expect(
          find.byKey(const Key('profile-account-actions-column')),
          findsOneWidget,
        );
        expect(carRect.width, closeTo(size.width - 48, 1));
      } else {
        expect(
          find.byKey(const Key('profile-account-actions-row')),
          findsOneWidget,
        );
      }

      expect(
        tester.getSize(find.byKey(const Key('add-garage-vehicle'))).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester
            .getSize(
              find.byKey(
                const ValueKey('delete-garage-car-android-car'),
              ),
            )
            .height,
        greaterThanOrEqualTo(48),
      );

      await tester.drag(
        find.byKey(const Key('profile-scroll-view')),
        const Offset(0, -1000),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'Falló al hacer scroll');
    }
  });

  testWidgets('shows configurable specialties only to mechanics and workshops',
      (tester) async {
    const mechanic = User(
      id: 'mechanic-1',
      email: 'mechanic@gmail.com',
      name: 'Mecánico',
      role: UserRole.mechanic,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _TestAuthNotifier(mechanic)),
          providerSpecialtiesProvider.overrideWith(
            (ref) async => const [
              Specialty(id: 'brakes', name: 'Frenos'),
            ],
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileTab())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProviderSpecialtiesCard), findsOneWidget);
    expect(find.text('Frenos'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    const store = User(
      id: 'store-1',
      email: 'store@gmail.com',
      name: 'Tienda',
      role: UserRole.store,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _TestAuthNotifier(store)),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileTab())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProviderSpecialtiesCard), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    const workshop = User(
      id: 'workshop-1',
      email: 'workshop@gmail.com',
      name: 'Taller',
      role: UserRole.workshop,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _TestAuthNotifier(workshop)),
          providerSpecialtiesProvider.overrideWith(
            (ref) async => const <Specialty>[],
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileTab())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProviderSpecialtiesCard), findsOneWidget);
    expect(find.text('Aún no has agregado especialidades.'), findsOneWidget);
  });

  testWidgets('shows exact location only to workshops and stores',
      (tester) async {
    for (final role in const [
      UserRole.workshop,
      UserRole.store,
      UserRole.mechanic,
      UserRole.consumer,
    ]) {
      final user = User(
        id: '${role.name}-location',
        email: '${role.name}@example.com',
        name: role.name,
        role: role,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _TestAuthNotifier(user)),
            if (role == UserRole.workshop || role == UserRole.mechanic)
              providerSpecialtiesProvider.overrideWith(
                (ref) async => const [],
              ),
            if (role == UserRole.store)
              storeCatalogProvider.overrideWith(
                (ref) async => const StoreCatalog(servesAllBrands: false),
              ),
            if (role == UserRole.consumer)
              userCarsProvider.overrideWith((ref) async => const []),
            if (role == UserRole.consumer)
              pendingReviewsProvider.overrideWith((ref) async => const []),
          ],
          child: const MaterialApp(home: Scaffold(body: ProfileTab())),
        ),
      );
      await tester.pump();

      expect(
        find.byType(ProviderLocationCard),
        role == UserRole.workshop || role == UserRole.store
            ? findsOneWidget
            : findsNothing,
        reason: 'El rol ${role.name} no debe configurar un punto comercial.',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('providers can open the reviews received by their own user id',
      (tester) async {
    const mechanic = User(
      id: 'mechanic-user-1',
      email: 'mechanic@gmail.com',
      name: 'Mecánico',
      role: UserRole.mechanic,
    );
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: ProfileTab()),
        ),
        GoRoute(
          path: RouteNames.providerReviews,
          builder: (_, state) => Scaffold(
            body: Text(
              '${state.pathParameters['targetId']}-'
              '${state.uri.queryParameters['view']}',
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _TestAuthNotifier(mechanic)),
          providerSpecialtiesProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reseñas de clientes'), findsOneWidget);
    final securitySize = tester.getSize(
      find.byKey(const Key('open-change-password')),
    );
    final reviewsSize = tester.getSize(
      find.byKey(const Key('open-received-reviews')),
    );
    expect(reviewsSize, securitySize);

    await tester.ensureVisible(
      find.byKey(const Key('open-received-reviews')),
    );
    await tester.tap(find.byKey(const Key('open-received-reviews')));
    await tester.pumpAndSettle();

    expect(find.text('mechanic-user-1-received'), findsOneWidget);
  });

  testWidgets('received reviews section is visible to every provider role',
      (tester) async {
    for (final role in const [
      UserRole.store,
      UserRole.workshop,
      UserRole.mechanic,
    ]) {
      final user = User(
        id: '${role.name}-1',
        email: '${role.name}@gmail.com',
        name: role.name,
        role: role,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _TestAuthNotifier(user)),
            if (role != UserRole.store)
              providerSpecialtiesProvider.overrideWith(
                (ref) async => const [],
              ),
          ],
          child: const MaterialApp(home: Scaffold(body: ProfileTab())),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('open-received-reviews')),
        findsOneWidget,
        reason: 'El rol ${role.name} debe ver sus reseñas',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
