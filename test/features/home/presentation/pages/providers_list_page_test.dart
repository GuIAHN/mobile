import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/service_type.dart';
import 'package:guiautomotriz_mobile/core/storage/secure_storage.dart';
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
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  @override
  Future<void> checkAuthStatus() async {}
}

void main() {
  Widget subject(
    ServiceType type, {
    double textScale = 1,
    AsyncValue<List<HomeItem>> items = const AsyncValue.data([]),
  }) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => ProvidersListPage(serviceType: type),
        ),
      ],
    );

    return ProviderScope(
      key: UniqueKey(),
      overrides: [
        authProvider.overrideWith((ref) => _TestAuthNotifier()),
        selectedServiceTypeProvider.overrideWith((ref) => type),
        filteredHomeItemsProvider.overrideWith(
          (ref) => items,
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
      ),
    );
  }

  for (final width in <double>[375, 430]) {
    for (final type in <ServiceType>[
      ServiceType.workshops,
      ServiceType.mechanic,
    ]) {
      for (final textScale in <double>[1, 1.3, 2]) {
        testWidgets(
          '${type.name} list renders at $width dp and ${textScale}x text',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = Size(width, 812);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(tester.view.resetPhysicalSize);

            await tester.pumpWidget(subject(type, textScale: textScale));
            await tester.pump();

            expect(
              find.text(
                type == ServiceType.workshops ? 'Talleres' : 'Mecánicos',
              ),
              findsOneWidget,
            );
          },
        );
      }
    }
  }

  testWidgets('loading, error, empty and data states remain renderable',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      subject(
        ServiceType.workshops,
        items: const AsyncValue.loading(),
      ),
    );
    expect(find.byType(ItemCardSkeleton), findsNWidgets(3));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      subject(
        ServiceType.workshops,
        items: AsyncValue.error(StateError('offline'), StackTrace.empty),
      ),
    );
    expect(find.text('No pudimos cargar los resultados.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(subject(ServiceType.workshops));
    expect(find.text('Aún no hay resultados en tu zona'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      subject(
        ServiceType.workshops,
        items: const AsyncValue.data([
          HomeItem(
            id: 'workshop-1',
            name: 'Taller Prueba',
            detail: 'Diagnóstico automotriz',
            rating: 4.8,
            reviews: 24,
            distanceKm: 2.4,
            isOpen: true,
            iconName: 'engineering_outlined',
            type: ServiceType.workshops,
          ),
        ]),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Taller Prueba'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
