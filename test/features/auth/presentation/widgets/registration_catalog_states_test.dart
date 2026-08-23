import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/widgets/store_catalog_helper.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/widgets/store_catalog_step.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/widgets/workshop_specialties_step.dart';
import 'package:guiautomotriz_mobile/features/catalog/domain/entities/category.dart';
import 'package:guiautomotriz_mobile/features/vehicles/domain/entities/brand.dart';

void main() {
  testWidgets('empty catalog directs the user to the hierarchical selector',
      (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoreCatalogStep(
            catalogo: const [],
            onAbrirSheetMarcas: (_) {},
            onAgregarSubcategoria: () => pressed = true,
          ),
        ),
      ),
    );

    expect(find.text('Selecciona lo que vendes'), findsOneWidget);
    expect(find.text('SELECCIONAR SUBCATEGORÍA'), findsOneWidget);
    await tester.tap(find.byKey(const Key('add-store-subcategory')));
    expect(pressed, isTrue);
  });

  testWidgets('configured catalog uses a compact summary card', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    const parent = Category(id: 'audio', name: 'Audio');
    const category = Category(
      id: 'amplification',
      name: 'Amplificación y Procesamiento',
      parentId: 'audio',
    );
    final brands = {
      for (var i = 0; i < 34; i++)
        Brand(id: '$i', name: 'Marca $i', brandType: 'car'),
    };
    final line = LineaCatalogo(
      category: category,
      parentCategory: parent,
      brands: brands,
      sparePartsTypes: {'ORIGINAL', 'GENERIC'},
    );
    LineaCatalogo? opened;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 700),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: StoreCatalogStep(
                catalogo: [line],
                onAbrirSheetMarcas: (value) => opened = value,
                onAgregarSubcategoria: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('34 marcas'), findsOneWidget);
    expect(find.text('Original · Genérico'), findsOneWidget);
    expect(find.text('Marca 0'), findsNothing);
    expect(find.text('Editar'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byKey(const ValueKey('store-catalog-category-amplification')),
    );
    expect(opened, same(line));
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
