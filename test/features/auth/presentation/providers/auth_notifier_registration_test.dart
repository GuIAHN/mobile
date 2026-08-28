import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/storage/secure_storage.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/entities/store_coverage_config.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/entities/user.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/register_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/usecases/upload_avatar_usecase.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/providers/auth_notifier.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const StoreCoverageConfig(
        servesAllBrands: false,
        brandIds: [],
        sparePartsTypes: [],
        subcategoryIds: [],
      ),
    );
  });

  test('provider registration success is not an authenticated session',
      () async {
    final repository = _MockAuthRepository();
    final storage = _MockSecureStorage();
    when(storage.hasToken).thenAnswer((_) async => false);
    when(
      () => repository.registerStore(
        email: any(named: 'email'),
        password: any(named: 'password'),
        name: any(named: 'name'),
        phone: any(named: 'phone'),
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        address: any(named: 'address'),
        rif: any(named: 'rif'),
        coverage: any(named: 'coverage'),
        hasDelivery: any(named: 'hasDelivery'),
        idToken: any(named: 'idToken'),
        provider: any(named: 'provider'),
        acceptedTerms: any(named: 'acceptedTerms'),
        rifPhotoPath: any(named: 'rifPhotoPath'),
      ),
    ).thenAnswer(
      (_) async => const Right(
        User(
          id: 'store-id',
          email: 'store@example.com',
          name: 'Repuestos Centro',
        ),
      ),
    );

    final notifier = AuthNotifier(
      loginUseCase: LoginUseCase(repository),
      registerUseCase: RegisterUseCase(repository),
      updateProfileUseCase: UpdateProfileUseCase(repository),
      uploadAvatarUseCase: UploadAvatarUseCase(repository),
      authRepository: repository,
      secureStorage: storage,
    );
    addTearDown(notifier.dispose);
    await Future<void>.delayed(Duration.zero);

    await notifier.registerStore(
      email: 'store@example.com',
      password: 'Secure1!',
      name: 'Repuestos Centro',
      phone: '4141234567',
      latitude: 10.4806,
      longitude: -66.9036,
      address: 'Caracas',
      rif: 'J123456789',
      coverage: const StoreCoverageConfig(
        servesAllBrands: false,
        subcategoryIds: ['category-id'],
        brandIds: ['brand-id'],
        sparePartsTypes: ['ORIGINAL'],
      ),
      hasDelivery: true,
      acceptedTerms: true,
      rifPhotoPath: '/tmp/rif.jpg',
    );

    expect(notifier.state.isProviderRegistrationSucceeded, isTrue);
    expect(notifier.state.isAuthenticated, isFalse);

    notifier.finishProviderRegistration();
    expect(notifier.state.isProviderRegistrationSucceeded, isFalse);
    expect(notifier.state.user, isNull);
  });
}
