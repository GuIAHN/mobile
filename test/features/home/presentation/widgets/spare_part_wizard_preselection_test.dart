import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/storage/secure_storage.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/entities/user.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/register_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/upload_avatar_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/providers/auth_state.dart';
import 'package:guiautomotriz_mobile/features/catalog/domain/entities/category_node.dart';
import 'package:guiautomotriz_mobile/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/spare_part_wizard/spare_part_wizard_page.dart';
import 'package:guiautomotriz_mobile/features/vehicles/domain/entities/user_car.dart';
import 'package:guiautomotriz_mobile/features/vehicles/presentation/providers/vehicle_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSecureStorage extends Mock implements SecureStorage {}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(AuthState initialState)
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
  const fixtureCar = UserCar(
    id: 'car-1',
    brand: 'Audi',
    model: '4000',
    year: 1985,
  );

  testWidgets('starts on step 1 with the initial vehicle selected',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userCarsProvider.overrideWith((ref) async => [fixtureCar]),
        ],
        child: const MaterialApp(
          home: SparePartWizardPage(
            initialVehicle: fixtureCar,
            initialModelId: 'model-1',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Paso 1 de 3'), findsOneWidget);
    expect(find.text('Audi 4000'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Selecciona la categoría'), findsNothing);
  });

  testWidgets('keeps the initial model when confirming the temporary car',
      (tester) async {
    const temporaryCar = UserCar(
      id: 'temp-car-1',
      brand: 'Audi',
      model: '4000',
      year: 1985,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userCarsProvider.overrideWith((ref) async => [temporaryCar]),
        ],
        child: const MaterialApp(
          home: SparePartWizardPage(
            initialVehicle: temporaryCar,
            initialModelId: 'model-1',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Audi 4000'));
    await tester.pump();
    await tester.ensureVisible(find.text('Continuar'));
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.textContaining('Paso 2 de 3'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is NetworkImage &&
            (widget.image as NetworkImage).url ==
                temporaryCar.computedBrandLogoUrl,
      ),
      findsOneWidget,
    );
    final state = tester.state(find.byType(SparePartWizardPage)) as dynamic;
    expect(state.debugTemporaryModelId, 'model-1');
  });

  testWidgets('shows a free-standing brand logo in the step summary',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userCarsProvider.overrideWith((ref) async => [fixtureCar]),
        ],
        child: const MaterialApp(
          home: SparePartWizardPage(initialVehicle: fixtureCar),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Audi 4000'));
    await tester.pump();
    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    final logo = find.byKey(const Key('wizard-summary-brand-logo'));
    expect(logo, findsOneWidget);
    final logoBox = tester.widget<SizedBox>(logo);
    expect(logoBox.width, greaterThan(48));
    expect(logoBox.width, greaterThan(logoBox.height!));
  });

  testWidgets('reports the visible vehicle position while swiping the garage',
      (tester) async {
    const secondCar = UserCar(
      id: 'car-2',
      brand: 'BMW',
      model: '6 Series',
      year: 1984,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userCarsProvider.overrideWith(
            (ref) async => [fixtureCar, secondCar],
          ),
        ],
        child: const MaterialApp(
          home: SparePartWizardPage(initialVehicle: fixtureCar),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Vehículo 1 de 2'), findsOneWidget);
    await tester.fling(
      find.byKey(const PageStorageKey('wizard-vehicle-carousel')),
      const Offset(-650, 0),
      1400,
    );
    await tester.pumpAndSettle();
    expect(find.text('Vehículo 2 de 2'), findsOneWidget);
  });

  testWidgets('switches dense steps immediately without overlapping pages',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userCarsProvider.overrideWith((ref) async => [fixtureCar]),
        ],
        child: const MaterialApp(
          home: SparePartWizardPage(initialVehicle: fixtureCar),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Audi 4000'));
    await tester.pump();
    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pump();

    final state = tester.state(find.byType(SparePartWizardPage)) as dynamic;
    expect(state.debugWizardPage, 1);
    expect(find.byKey(const ValueKey('step1')), findsNothing);
    expect(find.byKey(const ValueKey('step2')), findsOneWidget);

    await tester.pumpAndSettle();
    expect(state.debugWizardPage, 1);
    expect(find.byKey(const Key('wizard-step-title-1')), findsNothing);
    expect(find.byKey(const Key('wizard-step-title-2')), findsOneWidget);
  });

  testWidgets('jumps between steps when reduced motion is requested',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userCarsProvider.overrideWith((ref) async => [fixtureCar]),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const SparePartWizardPage(initialVehicle: fixtureCar),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Audi 4000'));
    await tester.pump();
    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pump();

    final state = tester.state(find.byType(SparePartWizardPage)) as dynamic;
    expect(state.debugWizardPage, 1);
    expect(find.byKey(const Key('wizard-step-title-1')), findsNothing);
    expect(find.byKey(const Key('wizard-step-title-2')), findsOneWidget);
  });

  testWidgets('keeps steps 1 and 2 stable across the responsive matrix',
      (tester) async {
    const viewports = [
      Size(320, 667),
      Size(390, 844),
      Size(430, 932),
    ];
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final viewport in viewports) {
      for (final textScale in [1.0, 2.0]) {
        tester.view.physicalSize = viewport;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              userCarsProvider.overrideWith((ref) async => [fixtureCar]),
            ],
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(textScale),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: const SparePartWizardPage(initialVehicle: fixtureCar),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Step 1 overflowed at $viewport and ${textScale}x text',
        );

        await tester.ensureVisible(find.text('Audi 4000'));
        await tester.pump();
        await tester.tap(find.text('Audi 4000'));
        await tester.pump();
        await tester.ensureVisible(find.text('Continuar'));
        await tester.tap(find.text('Continuar'));
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Step 2 overflowed at $viewport and ${textScale}x text',
        );
      }
    }
  });

  testWidgets(
      'shows the saved profile location in step 3 without opening the map',
      (tester) async {
    const user = User(
      id: 'user-1',
      email: 'driver@example.com',
      name: 'Driver',
      latitude: 14.0723,
      longitude: -87.1921,
    );
    final authNotifier = _TestAuthNotifier(
      const AuthState(status: AuthStatus.authenticated, user: user),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => authNotifier),
          userCarsProvider.overrideWith((ref) async => [fixtureCar]),
          categoryTreeProvider.overrideWith(
            (ref) async => const [
              CategoryNode(
                id: 'brakes',
                name: 'Frenos',
                children: [
                  CategoryNode(
                    id: 'pads',
                    name: 'Pastillas de freno',
                    parentId: 'brakes',
                  ),
                ],
              ),
            ],
          ),
        ],
        child: const MaterialApp(
          home: SparePartWizardPage(initialVehicle: fixtureCar),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selecciona categoría y subcategoría'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pastillas de freno'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('OEM'));
    await tester.tap(find.text('OEM'));
    await tester.pump();
    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('14.0723, -87.1921'), findsOneWidget);
    expect(find.text('Última ubicación guardada'), findsOneWidget);

    var submitButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Enviar solicitud'),
    );
    expect(submitButton.onPressed, isNull);

    await tester.enterText(
      find.byType(TextField),
      'Pastillas delanteras con sensor de desgaste',
    );
    await tester.pump();

    submitButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Enviar solicitud'),
    );
    expect(submitButton.onPressed, isNotNull);
  });
}
