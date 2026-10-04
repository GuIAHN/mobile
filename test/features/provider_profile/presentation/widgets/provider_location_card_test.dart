import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/user_role.dart';
import 'package:guiautomotriz_mobile/core/error/failures.dart';
import 'package:guiautomotriz_mobile/core/storage/secure_storage.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/entities/user.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/register_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/upload_avatar_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/providers/auth_state.dart';
import 'package:guiautomotriz_mobile/shared/location/domain/entities/request_location_selection.dart';
import 'package:guiautomotriz_mobile/features/provider_profile/presentation/widgets/provider_location_card.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSecureStorage extends Mock implements SecureStorage {}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(AuthRepository repository, User user)
      : super(
          loginUseCase: LoginUseCase(repository),
          registerUseCase: RegisterUseCase(repository),
          updateProfileUseCase: UpdateProfileUseCase(repository),
          uploadAvatarUseCase: UploadAvatarUseCase(repository),
          authRepository: repository,
          secureStorage: _MockSecureStorage(),
        ) {
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  @override
  Future<void> checkAuthStatus() async {}
}

const _store = User(
  id: 'store-1',
  email: 'store@example.com',
  name: 'Repuestos Centro',
  role: UserRole.store,
);

Widget _testApp({
  User user = _store,
  ProviderLocationPicker? picker,
  ProviderLocationSaver? saver,
  Size size = const Size(390, 844),
  TextScaler textScaler = TextScaler.noScaling,
}) {
  final repository = _MockAuthRepository();
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(
        (ref) => _TestAuthNotifier(repository, user),
      ),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size, textScaler: textScaler),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ProviderLocationCard(
              user: user,
              locationPicker: picker,
              locationSaver: saver,
              previewBuilder: (_, point) => SizedBox(
                height: 176,
                child: Center(
                  child: Text('${point.latitude}, ${point.longitude}'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  const selected = RequestLocationSelection(
    latitude: 14.0723,
    longitude: -87.1921,
    label: 'Tegucigalpa',
    source: RequestLocationSource.mapTap,
  );

  testWidgets('shows an actionable empty state with a 48dp+ target',
      (tester) async {
    await tester.pumpWidget(_testApp());

    expect(find.byKey(const Key('provider-location-empty')), findsOneWidget);
    expect(find.text('Aún no has definido tu ubicación.'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const Key('configure-provider-location')))
          .height,
      greaterThanOrEqualTo(48),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('saves the selected point and shows the configured data state',
      (tester) async {
    LatLng? saved;
    await tester.pumpWidget(
      _testApp(
        picker: (_, __) async => selected,
        saver: (latitude, longitude) async {
          saved = LatLng(latitude, longitude);
          return null;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('configure-provider-location')));
    await tester.pump();
    await tester.pump();

    expect(saved, const LatLng(14.0723, -87.1921));
    expect(find.byKey(const Key('provider-location-preview')), findsOneWidget);
    expect(find.text('14.0723, -87.1921'), findsOneWidget);
    expect(find.text('Ubicación configurada'), findsOneWidget);
    expect(find.byKey(const Key('edit-provider-location')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the chosen point and offers recovery after a save error',
      (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      _testApp(
        picker: (_, __) async => selected,
        saver: (_, __) async {
          attempts++;
          return attempts == 1 ? const NetworkFailure() : null;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('configure-provider-location')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Sin conexión a internet.'), findsOneWidget);
    expect(find.byKey(const Key('provider-location-preview')), findsOneWidget);
    expect(
      find.byKey(const Key('retry-provider-location-save')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('choose-another-provider-location')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('retry-provider-location-save')));
    await tester.pump();
    await tester.pump();

    expect(attempts, 2);
    expect(find.text('Ubicación configurada'), findsOneWidget);
    expect(find.text('Sin conexión a internet.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adapts to small and large phones with large text',
      (tester) async {
    for (final size in const [Size(320, 700), Size(430, 932)]) {
      await tester.pumpWidget(
        _testApp(
          user: const User(
            id: 'workshop-1',
            email: 'workshop@example.com',
            name: 'Taller Central',
            role: UserRole.workshop,
            latitude: 14.0723,
            longitude: -87.1921,
          ),
          size: size,
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pump();

      expect(find.text('Punto de tu taller'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('edit-provider-location'))).height,
        greaterThanOrEqualTo(48),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('keeps the edit action in the same row as the location label',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        user: const User(
          id: 'store-1',
          email: 'store@example.com',
          name: 'Repuestos Centro',
          role: UserRole.store,
          latitude: 14.0723,
          longitude: -87.1921,
        ),
        size: const Size(320, 700),
      ),
    );

    final labelTop = tester.getTopLeft(find.text('UBICACIÓN')).dy;
    final actionTop =
        tester.getTopLeft(find.byKey(const Key('edit-provider-location'))).dy;
    final titleTop = tester.getTopLeft(find.text('Punto de tu tienda')).dy;
    final labelBottom = tester.getBottomLeft(find.text('UBICACIÓN')).dy;

    expect((labelTop - actionTop).abs(), lessThanOrEqualTo(3));
    expect(titleTop - labelBottom, lessThanOrEqualTo(8));
    expect(tester.takeException(), isNull);
  });

  test('auth notifier retains submitted coordinates when PATCH omits location',
      () async {
    final repository = _MockAuthRepository();
    const current = User(
      id: 'store-1',
      email: 'store@example.com',
      name: 'Repuestos Centro',
      role: UserRole.store,
      latitude: 10,
      longitude: -66,
    );
    const responseWithoutLocation = User(
      id: 'store-1',
      email: 'store@example.com',
      name: 'Repuestos Centro',
      role: UserRole.store,
    );
    when(
      () => repository.updateProfile(
        name: null,
        photo: null,
        phone: null,
        latitude: 14.0723,
        longitude: -87.1921,
      ),
    ).thenAnswer((_) async => const Right(responseWithoutLocation));
    final notifier = _TestAuthNotifier(repository, current);
    addTearDown(notifier.dispose);

    final failure = await notifier.updateLocation(
      latitude: 14.0723,
      longitude: -87.1921,
    );

    expect(failure, isNull);
    expect(notifier.state.user?.latitude, 14.0723);
    expect(notifier.state.user?.longitude, -87.1921);
    expect(notifier.state.status, AuthStatus.authenticated);
  });
}
