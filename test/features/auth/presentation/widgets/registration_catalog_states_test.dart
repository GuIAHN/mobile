import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/pages/register_store_page.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/providers/social_registration_state.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/widgets/store_catalog_helper.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/widgets/store_catalog_step.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/widgets/store_summary_step.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/widgets/workshop_specialties_step.dart';
import 'package:guiautomotriz_mobile/features/catalog/domain/entities/category.dart';
import 'package:guiautomotriz_mobile/features/catalog/domain/entities/category_node.dart';
import 'package:guiautomotriz_mobile/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:guiautomotriz_mobile/features/vehicles/domain/entities/brand.dart';

void main() {
  testWidgets('catalog exposes loading and empty states', (tester) async {
    final pendingTree = Completer<List<CategoryNode>>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryTreeProvider.overrideWith((ref) => pendingTree.future),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: StoreCatalogStep(
              catalogo: const [],
              onSubcategoryToggled: (_, __) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Cargando categorías…'), findsOneWidget);

    pendingTree.complete(const []);
    await tester.pumpAndSettle();

    expect(find.text('No hay categorías disponibles.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog exposes a recoverable error state', (tester) async {
    var attempts = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryTreeProvider.overrideWith((ref) async {
            attempts++;
            throw Exception('network failure');
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: StoreCatalogStep(
              catalogo: const [],
              onSubcategoryToggled: (_, __) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No pudimos cargar las categorías.'), findsOneWidget);
    await tester.tap(find.text('REINTENTAR'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('category expands and allows multiple subcategory selection',
      (tester) async {
    Category? selectedCategory;
    Category? selectedSubcategory;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryTreeProvider.overrideWith(
            (ref) async => const [
              CategoryNode(
                id: 'motor',
                name: 'Motor',
                children: [
                  CategoryNode(
                    id: 'pistones',
                    name: 'Pistones',
                    parentId: 'motor',
                  ),
                  CategoryNode(
                    id: 'correas',
                    name: 'Correas',
                    parentId: 'motor',
                  ),
                ],
              ),
            ],
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: StoreCatalogStep(
              catalogo: const [],
              onSubcategoryToggled: (category, subcategory) {
                selectedCategory = category;
                selectedSubcategory = subcategory;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Motor'), findsOneWidget);
    expect(find.text('Pistones'), findsNothing);
    await tester.tap(find.text('Motor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pistones'));
    expect(selectedCategory?.id, 'motor');
    expect(selectedSubcategory?.id, 'pistones');
  });

  testWidgets('store catalog adapts to small and large phone layouts',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 600);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final socialRegistration = SocialRegistrationNotifier()
      ..setData(
        idToken: 'token',
        provider: 'GOOGLE',
        email: 'tienda@example.com',
        name: 'Repuestos GuIA',
      );
    final roots = List.generate(
      12,
      (index) => CategoryNode(
        id: 'root-$index',
        name: 'Sistema $index',
        children: [
          CategoryNode(
            id: 'child-$index',
            name: 'Componente $index',
            parentId: 'root-$index',
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialRegistrationProvider.overrideWith(
            (ref) => socialRegistration,
          ),
          categoryTreeProvider.overrideWith((ref) async => roots),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: const RegisterStorePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('phone-subscriber-input')),
      '1234567',
    );
    await tester.enterText(find.byType(TextFormField).last, '123456789');
    await tester.pump();

    const continueButton = Key('register-store-continue');
    await tester.scrollUntilVisible(
      find.byKey(continueButton),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(continueButton));
    await tester.pumpAndSettle();
    expect(find.text('Protege tu Cuenta'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(continueButton),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(continueButton));
    await tester.pumpAndSettle();

    expect(find.text('Catálogo'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Sistema 11'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(StoreCatalogStep), findsOneWidget);
    expect(find.text('Sistema 11'), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(430, 932);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
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
    var opened = false;

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
              child: StoreSummaryStep(
                catalogo: [line],
                onConfigurarCatalogo: () => opened = true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Marcas y tipos configurados'), findsOneWidget);
    expect(find.text('EDITAR CONFIGURACIÓN'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(
      find.byKey(const Key('configure-general-store-catalog')),
    );
    await tester.tap(find.byKey(const Key('configure-general-store-catalog')));
    expect(opened, isTrue);
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
