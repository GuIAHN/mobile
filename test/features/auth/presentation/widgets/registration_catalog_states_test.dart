import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/widgets/store_catalog_step.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/widgets/workshop_specialties_step.dart';

void main() {
  testWidgets('catalog distinguishes loading, error and empty states',
      (tester) async {
    Widget subject({bool loading = false, Object? error}) => MaterialApp(
          home: Scaffold(
            body: StoreCatalogStep(
              catalogo: const [],
              categories: const [],
              onAbrirSheetMarcas: (_) {},
              isLoading: loading,
              loadError: error,
              onRetry: () {},
            ),
          ),
        );

    await tester.pumpWidget(subject(loading: true));
    expect(find.text('Cargando categorías…'), findsOneWidget);

    await tester.pumpWidget(subject(error: Exception('technical detail')));
    expect(find.text('No pudimos cargar las categorías'), findsOneWidget);
    expect(find.text('REINTENTAR'), findsOneWidget);
    expect(find.textContaining('technical detail'), findsNothing);

    await tester.pumpWidget(subject());
    expect(find.text('No hay categorías disponibles'), findsOneWidget);
  });

  testWidgets('specialties exposes a recoverable error state', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkshopSpecialtiesStep(
            selectedSpecialtyIds: const <String>{},
            onSpecialtyToggled: (_) {},
            specialties: const [],
            loadError: Exception('socket failure'),
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('No pudimos cargar las especialidades'), findsOneWidget);
    await tester.tap(find.text('REINTENTAR'));
    expect(retried, isTrue);
  });
}
