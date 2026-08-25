import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/service_type.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/user_role.dart';
import 'package:guiautomotriz_mobile/core/storage/secure_storage.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/entities/user.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/register_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/upload_avatar_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/providers/auth_state.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/home_item.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/pages/providers_list_page.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:guiautomotriz_mobile/shared/widgets/skeleton_loader.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSecureStorage extends Mock implements SecureStorage {}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier({UserRole role = UserRole.store})
      : super(
          loginUseCase: LoginUseCase(_MockAuthRepository()),
          registerUseCase: RegisterUseCase(_MockAuthRepository()),
          updateProfileUseCase: UpdateProfileUseCase(_MockAuthRepository()),
          uploadAvatarUseCase: UploadAvatarUseCase(_MockAuthRepository()),
          authRepository: _MockAuthRepository(),
          secureStorage: _MockSecureStorage(),
        ) {
    state = AuthState(
      status: AuthStatus.authenticated,
      user: User(
        id: 'store-1',
        email: 'store@example.com',
        name: 'Repuestos Norte',
        role: role,
      ),
    );
  }

  @override
  Future<void> checkAuthStatus() async {}
}

Widget _subject({
  required AsyncValue<List<HomeItem>> state,
  required Size size,
  required EdgeInsets padding,
  double textScale = 1,
  bool disableAnimations = false,
  ServiceType serviceType = ServiceType.workshops,
  UserRole role = UserRole.store,
}) {
  return ProviderScope(
    key: UniqueKey(),
    overrides: [
      authProvider.overrideWith((ref) => _TestAuthNotifier(role: role)),
      filteredHomeItemsProvider.overrideWith((ref) => state),
    ],
    child: MediaQuery(
      data: MediaQueryData(
        size: size,
        padding: padding,
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: MaterialApp(
        home: ProvidersListPage(serviceType: serviceType),
      ),
    ),
  );
}

void main() {
  for (final serviceType in [ServiceType.workshops, ServiceType.mechanic]) {
    testWidgets(
      'shows vehicle context without compatibility wording in the ${serviceType.name} list',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(const Size(430, 932));

        await tester.pumpWidget(
          _subject(
            state: const AsyncValue.data([]),
            size: const Size(430, 932),
            padding: const EdgeInsets.only(top: 59, bottom: 34),
            serviceType: serviceType,
            role: UserRole.consumer,
          ),
        );
        await tester.pump();

        expect(find.text('Selecciona el vehículo'), findsOneWidget);
        expect(find.textContaining('Lo incluiremos'), findsNothing);
        expect(find.textContaining('COMPATIBILIDAD'), findsNothing);
        expect(
          tester
              .getSize(find.byKey(const Key('vehicle-context-action')))
              .height,
          greaterThanOrEqualTo(48),
        );
      },
    );
  }

  testWidgets(
    'lays out the pinned search header at the reported phone dimensions',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(430, 932));

      await tester.pumpWidget(
        _subject(
          state: const AsyncValue.data([]),
          size: const Size(430, 932),
          padding: const EdgeInsets.only(top: 59, bottom: 34),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Talleres cerca de tu negocio'), findsOneWidget);

      final backButton = find.ancestor(
        of: find.byIcon(Icons.arrow_back_rounded),
        matching: find.byType(IconButton),
      );
      expect(tester.getSize(backButton).shortestSide, greaterThanOrEqualTo(48));

      final filterButton = find
          .ancestor(
            of: find.byIcon(Icons.tune_rounded),
            matching: find.byType(GestureDetector),
          )
          .first;
      expect(
        tester.getSize(filterButton).shortestSide,
        greaterThanOrEqualTo(48),
      );
    },
  );

  testWidgets('keeps the loading state layout-safe on a small phone',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(375, 667));

    await tester.pumpWidget(
      _subject(
        state: const AsyncValue.loading(),
        size: const Size(375, 667),
        padding: const EdgeInsets.only(top: 24),
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(ItemCardSkeleton), findsNWidgets(3));
  });

  testWidgets('renders the recoverable error state on a small phone',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(375, 812));

    await tester.pumpWidget(
      _subject(
        state: AsyncValue.error(Exception('network'), StackTrace.empty),
        size: const Size(375, 812),
        padding: const EdgeInsets.only(top: 44, bottom: 34),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('No pudimos cargar los resultados.'), findsOneWidget);
  });

  testWidgets('renders data with large text and reduced motion',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(430, 932));

    await tester.pumpWidget(
      _subject(
        state: const AsyncValue.data([
          HomeItem(
            id: 'workshop-1',
            name: 'Taller Norte',
            detail: 'Diagnóstico y frenos',
            rating: 4.8,
            reviews: 24,
            distanceKm: 2.4,
            isOpen: true,
            iconName: 'warehouse_outlined',
            type: ServiceType.workshops,
          ),
        ]),
        size: const Size(430, 932),
        padding: const EdgeInsets.only(top: 59, bottom: 34),
        textScale: 2,
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Taller Norte'), findsOneWidget);
  });

  testWidgets('changes provider pages without replacing the screen',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(430, 932));

    final items = List.generate(
      7,
      (index) => HomeItem(
        id: 'workshop-$index',
        name: 'Taller ${index + 1}',
        detail: 'Diagnóstico y frenos',
        rating: 4.8,
        reviews: 24,
        distanceKm: 2.4,
        isOpen: true,
        iconName: 'warehouse_outlined',
        type: ServiceType.workshops,
      ),
    );

    await tester.pumpWidget(
      _subject(
        state: AsyncValue.data(items),
        size: const Size(430, 932),
        padding: const EdgeInsets.only(top: 59, bottom: 34),
        disableAnimations: true,
      ),
    );
    await tester.pump();

    expect(find.text('Taller 1'), findsOneWidget);
    expect(find.text('Taller 7'), findsNothing);

    await tester.scrollUntilVisible(
      find.byTooltip('Página siguiente'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Página 1 de 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Página siguiente'));
    await tester.pumpAndSettle();

    expect(find.byType(ItemCardSkeleton), findsNothing);
    expect(find.text('Taller 1'), findsNothing);
    expect(find.text('Taller 7'), findsOneWidget);
  });
}
