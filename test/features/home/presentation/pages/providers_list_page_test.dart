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
  _TestAuthNotifier()
      : super(
          loginUseCase: LoginUseCase(_MockAuthRepository()),
          registerUseCase: RegisterUseCase(_MockAuthRepository()),
          updateProfileUseCase: UpdateProfileUseCase(_MockAuthRepository()),
          uploadAvatarUseCase: UploadAvatarUseCase(_MockAuthRepository()),
          authRepository: _MockAuthRepository(),
          secureStorage: _MockSecureStorage(),
        ) {
    state = const AuthState(
      status: AuthStatus.authenticated,
      user: User(
        id: 'store-1',
        email: 'store@example.com',
        name: 'Repuestos Norte',
        role: UserRole.store,
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
}) {
  return ProviderScope(
    key: UniqueKey(),
    overrides: [
      authProvider.overrideWith((ref) => _TestAuthNotifier()),
      filteredHomeItemsProvider.overrideWith((ref) => state),
    ],
    child: MediaQuery(
      data: MediaQueryData(
        size: size,
        padding: padding,
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: const MaterialApp(
        home: ProvidersListPage(serviceType: ServiceType.workshops),
      ),
    ),
  );
}

void main() {
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
}
