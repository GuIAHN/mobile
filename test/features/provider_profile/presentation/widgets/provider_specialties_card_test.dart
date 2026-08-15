import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/error/failures.dart';
import 'package:guiautomotriz_mobile/features/catalog/domain/entities/specialty.dart';
import 'package:guiautomotriz_mobile/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:guiautomotriz_mobile/features/provider_profile/domain/repositories/provider_profile_repository.dart';
import 'package:guiautomotriz_mobile/features/provider_profile/domain/usecases/get_provider_specialties_usecase.dart';
import 'package:guiautomotriz_mobile/features/provider_profile/domain/usecases/update_provider_specialties_usecase.dart';
import 'package:guiautomotriz_mobile/features/provider_profile/presentation/providers/provider_profile_providers.dart';
import 'package:guiautomotriz_mobile/features/provider_profile/presentation/widgets/provider_specialties_card.dart';

class _FakeProviderProfileRepository implements ProviderProfileRepository {
  List<Specialty> ownSpecialties = const [];
  List<String>? updatedIds;
  Failure? updateFailure;
  int getCalls = 0;

  @override
  Future<Either<Failure, List<Specialty>>> getOwnSpecialties() async {
    getCalls++;
    return Right(ownSpecialties);
  }

  @override
  Future<Either<Failure, List<Specialty>>> updateOwnSpecialties(
    List<String> specialtyIds,
  ) async {
    updatedIds = specialtyIds;
    if (updateFailure != null) return Left(updateFailure!);
    return Right(
      specialtyIds
          .map((id) => Specialty(id: id, name: id))
          .toList(growable: false),
    );
  }
}

const _brakes = Specialty(id: 'brakes', name: 'Frenos');
const _electricity = Specialty(id: 'electricity', name: 'Electricidad');

Widget _testApp({
  required List<Override> overrides,
  MediaQueryData mediaQuery = const MediaQueryData(size: Size(390, 844)),
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: MediaQuery(
        data: mediaQuery,
        child: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: ProviderSpecialtiesCard(),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows configured specialties and saves additions and removals',
      (tester) async {
    final repository = _FakeProviderProfileRepository()
      ..ownSpecialties = const [_brakes];

    await tester.pumpWidget(
      _testApp(
        overrides: [
          getProviderSpecialtiesUseCaseProvider.overrideWithValue(
            GetProviderSpecialtiesUseCase(repository),
          ),
          specialtiesProvider.overrideWith(
            (ref) async => const [_brakes, _electricity],
          ),
          updateProviderSpecialtiesUseCaseProvider.overrideWithValue(
            UpdateProviderSpecialtiesUseCase(repository),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Frenos'), findsOneWidget);
    await tester.tap(find.byKey(const Key('edit-provider-specialties')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('specialty-option-brakes')));
    await tester.tap(find.byKey(const Key('specialty-option-electricity')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-provider-specialties')));
    await tester.pumpAndSettle();

    expect(repository.updatedIds, ['electricity']);
    expect(repository.getCalls, 1);
    expect(find.text('electricity'), findsOneWidget);
    expect(find.text('Editar especialidades'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the editor open and explains a save failure',
      (tester) async {
    final repository = _FakeProviderProfileRepository()
      ..updateFailure = const NetworkFailure();

    await tester.pumpWidget(
      _testApp(
        overrides: [
          providerSpecialtiesProvider.overrideWith(
            (ref) async => const [_brakes],
          ),
          specialtiesProvider.overrideWith(
            (ref) async => const [_brakes, _electricity],
          ),
          updateProviderSpecialtiesUseCaseProvider.overrideWithValue(
            UpdateProviderSpecialtiesUseCase(repository),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-provider-specialties')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('specialty-option-electricity')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-provider-specialties')));
    await tester.pumpAndSettle();

    expect(find.text('Sin conexión a internet.'), findsOneWidget);
    expect(find.text('Editar especialidades'), findsOneWidget);
  });

  testWidgets('shows loading and error states without exposing raw errors',
      (tester) async {
    final pending = Completer<List<Specialty>>();
    await tester.pumpWidget(
      _testApp(
        overrides: [
          providerSpecialtiesProvider.overrideWith((ref) => pending.future),
        ],
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Cargando especialidades'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      _testApp(
        overrides: [
          providerSpecialtiesProvider.overrideWith(
            (ref) => Future<List<Specialty>>.error(Exception('secret')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No pudimos cargar las especialidades. Inténtalo nuevamente.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('secret'), findsNothing);
  });

  testWidgets('fits a small phone with large text', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _testApp(
        mediaQuery: const MediaQueryData(
          size: Size(320, 700),
          textScaler: TextScaler.linear(2),
        ),
        overrides: [
          providerSpecialtiesProvider.overrideWith(
            (ref) async => const [_brakes, _electricity],
          ),
          specialtiesProvider.overrideWith(
            (ref) async => const [_brakes, _electricity],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('edit-provider-specialties')));
    await tester.pumpAndSettle();

    expect(find.text('Editar especialidades'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits a large phone width', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 932);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _testApp(
        mediaQuery: const MediaQueryData(size: Size(430, 932)),
        overrides: [
          providerSpecialtiesProvider.overrideWith(
            (ref) async => const [_brakes, _electricity],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
