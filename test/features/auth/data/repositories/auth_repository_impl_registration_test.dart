import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/storage/secure_storage.dart';
import 'package:guiautomotriz_mobile/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:guiautomotriz_mobile/features/auth/data/models/user_model.dart';
import 'package:guiautomotriz_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/entities/store_coverage_config.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class _MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  late _MockAuthRemoteDataSource remoteDataSource;
  late _MockSecureStorage secureStorage;
  late AuthRepositoryImpl repository;

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

  setUp(() {
    remoteDataSource = _MockAuthRemoteDataSource();
    secureStorage = _MockSecureStorage();
    repository = AuthRepositoryImpl(
      remoteDataSource: remoteDataSource,
      secureStorage: secureStorage,
    );
  });

  test('store registration stays unauthenticated while approval is pending',
      () async {
    const registeredStore = UserModel(
      id: 'store-id',
      email: 'store@example.com',
      name: 'Repuestos Centro',
    );
    when(
      () => remoteDataSource.registerStore(
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
        mercantilRegistryPath: any(named: 'mercantilRegistryPath'),
      ),
    ).thenAnswer((_) async => registeredStore);

    final result = await repository.registerStore(
      email: registeredStore.email,
      password: 'Secure1!',
      name: registeredStore.name,
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
      mercantilRegistryPath: '/tmp/registry.jpg',
    );

    expect(result.getOrElse(() => throw StateError('registration failed')),
        registeredStore);
    verifyNever(
      () => remoteDataSource.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
    verifyNever(() => remoteDataSource.getCurrentUser());
    verifyNever(() => secureStorage.saveToken(any()));
    verifyNever(() => secureStorage.saveRefreshToken(any()));
    verifyNever(() => secureStorage.saveUserId(any()));
  });

  test('mechanic registration stays unauthenticated while approval is pending',
      () async {
    const registeredMechanic = UserModel(
      id: 'mechanic-id',
      email: 'mechanic@example.com',
      name: 'Ana Mecánica',
    );
    when(
      () => remoteDataSource.registerMechanic(
        email: any(named: 'email'),
        password: any(named: 'password'),
        name: any(named: 'name'),
        phone: any(named: 'phone'),
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        description: any(named: 'description'),
        isWorkshop: any(named: 'isWorkshop'),
        identification: any(named: 'identification'),
        specialtyIds: any(named: 'specialtyIds'),
        idToken: any(named: 'idToken'),
        provider: any(named: 'provider'),
        acceptedTerms: any(named: 'acceptedTerms'),
        idPhotoPath: any(named: 'idPhotoPath'),
        rifPhotoPath: any(named: 'rifPhotoPath'),
        mercantilRegistryPath: any(named: 'mercantilRegistryPath'),
      ),
    ).thenAnswer((_) async => registeredMechanic);

    final result = await repository.registerMechanic(
      email: registeredMechanic.email,
      password: 'Secure1!',
      name: registeredMechanic.name,
      phone: '4141234567',
      latitude: 10.4806,
      longitude: -66.9036,
      description: 'Especialista',
      isWorkshop: false,
      identification: 'V12345678',
      specialtyIds: const ['specialty-id'],
      acceptedTerms: true,
      idPhotoPath: '/tmp/id.jpg',
    );

    expect(result.getOrElse(() => throw StateError('registration failed')),
        registeredMechanic);
    verifyNever(
      () => remoteDataSource.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
    verifyNever(() => remoteDataSource.getCurrentUser());
    verifyNever(() => secureStorage.saveToken(any()));
    verifyNever(() => secureStorage.saveRefreshToken(any()));
    verifyNever(() => secureStorage.saveUserId(any()));
  });
}
