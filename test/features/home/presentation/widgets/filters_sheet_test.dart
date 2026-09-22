import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/service_type.dart';
import 'package:guiautomotriz_mobile/features/catalog/domain/entities/specialty.dart';
import 'package:guiautomotriz_mobile/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/home_filters.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/filters_sheet.dart';

void main() {
  const specialties = <Specialty>[
    Specialty(
      id: 'tuning',
      name: 'Afinamiento y Reprogramación de Computadoras (Tuning/Remap)',
    ),
    Specialty(id: 'ac', name: 'Aire Acondicionado y Climatización'),
  ];

  Widget buildSubject({
    Size size = const Size(375, 812),
    double textScale = 1,
    EdgeInsets safeArea = EdgeInsets.zero,
    required Future<List<Specialty>> Function(Ref ref) specialtyLoader,
  }) {
    return ProviderScope(
      overrides: [specialtiesProvider.overrideWith(specialtyLoader)],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            padding: safeArea,
            textScaler: TextScaler.linear(textScale),
          ),
          child: const Scaffold(
            body: FiltersSheet(
              initialFilters: HomeFilters(),
              serviceType: ServiceType.workshops,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('keeps long specialties inside small and large phone widths',
      (tester) async {
    for (final size in const [Size(375, 667), Size(430, 932)]) {
      await tester.pumpWidget(
        buildSubject(
          size: size,
          safeArea: const EdgeInsets.only(top: 47, bottom: 34),
          specialtyLoader: (ref) async => specialties,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(specialties.first.name), findsOneWidget);
      expect(
        tester.getRect(find.text(specialties.first.name)).right,
        lessThanOrEqualTo(tester.getRect(find.byType(FiltersSheet)).right),
      );
    }
  });

  testWidgets('supports large text without overflowing the sheet',
      (tester) async {
    await tester.pumpWidget(
      buildSubject(
        textScale: 2,
        specialtyLoader: (ref) async => specialties,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(specialties.first.name), findsOneWidget);
  });

  testWidgets('renders specialty loading, empty, error, and data states',
      (tester) async {
    final pending = Completer<List<Specialty>>();
    await tester.pumpWidget(
      buildSubject(specialtyLoader: (ref) => pending.future),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending.complete(const <Specialty>[]);
    await tester.pumpAndSettle();
    expect(find.text('No hay especialidades disponibles'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      buildSubject(
        specialtyLoader: (ref) => Future<List<Specialty>>.error(
          Exception('backend details'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Error al cargar especialidades'), findsOneWidget);
    expect(find.textContaining('backend details'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      buildSubject(specialtyLoader: (ref) async => specialties),
    );
    await tester.pumpAndSettle();
    expect(find.text(specialties.first.name), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
