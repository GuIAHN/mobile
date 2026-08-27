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
import 'package:guiautomotriz_mobile/features/catalog/data/models/category_node_model.dart';
import 'package:guiautomotriz_mobile/features/catalog/domain/entities/category.dart';
import 'package:guiautomotriz_mobile/features/catalog/domain/entities/category_node.dart';
import 'package:guiautomotriz_mobile/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:guiautomotriz_mobile/features/vehicles/domain/entities/brand.dart';
import 'package:guiautomotriz_mobile/features/vehicles/presentation/providers/vehicle_providers.dart';

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

  testWidgets('category cards open a focused selectable spare-part list',
      (tester) async {
    Category? selectedCategory;
    Category? selectedSubcategory;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryTreeProvider.overrideWith(
            (ref) async => const <CategoryNodeModel>[
              CategoryNodeModel(
                id: 'motor',
                name: 'Motor',
                children: <CategoryNodeModel>[
                  CategoryNodeModel(
                    id: 'pistones',
                    name: 'Pistones',
                    parentId: 'motor',
                  ),
                  CategoryNodeModel(
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
    await tester.tap(find.byKey(const Key('store-category-motor')));
    await tester.pumpAndSettle();
    expect(find.text('Pistones'), findsOneWidget);
    expect(find.text('Correas'), findsOneWidget);
    await tester.tap(find.text('Pistones'));
    await tester.pump();
    expect(selectedCategory?.id, 'motor');
    expect(selectedSubcategory?.id, 'pistones');
    expect(find.text('LISTO · 1'), findsOneWidget);
  });

  testWidgets('category sheet can select and clear every subcategory',
      (tester) async {
    final toggledIds = <String>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryTreeProvider.overrideWith(
            (ref) async => const <CategoryNodeModel>[
              CategoryNodeModel(
                id: 'motor',
                name: 'Motor',
                children: <CategoryNodeModel>[
                  CategoryNodeModel(
                    id: 'pistones',
                    name: 'Pistones',
                    parentId: 'motor',
                  ),
                  CategoryNodeModel(
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
              onSubcategoryToggled: (_, subcategory) {
                toggledIds.add(subcategory.id);
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('store-category-motor')));
    await tester.pumpAndSettle();

    final toggleAll = find.byKey(
      const Key('toggle-all-store-subcategories'),
    );
    expect(toggleAll, findsOneWidget);
    expect(find.text('Seleccionar todas'), findsOneWidget);

    await tester.tap(toggleAll);
    await tester.pump();
    expect(toggledIds, containsAll(<String>['pistones', 'correas']));
    expect(find.text('2 elegidos'), findsOneWidget);
    expect(find.text('Quitar todas'), findsOneWidget);
    expect(find.text('LISTO · 2'), findsOneWidget);

    await tester.tap(toggleAll);
    await tester.pump();
    expect(toggledIds.length, 4);
    expect(find.text('0 elegidos'), findsOneWidget);
    expect(find.text('Seleccionar todas'), findsOneWidget);
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

    expect(find.text('Tu Catálogo'), findsOneWidget);
    expect(find.byType(AnimatedSwitcher), findsNothing);
    final pageSafeArea = tester.widget<SafeArea>(find.byType(SafeArea).first);
    expect(pageSafeArea.bottom, isFalse);
    await tester.scrollUntilVisible(
      find.byKey(const Key('store-category-root-0')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('CATEGORÍAS'), findsNothing);
    expect(find.byType(StoreCatalogStep), findsOneWidget);
    expect(find.text('Sistema 0'), findsOneWidget);
    expect(find.text('Componente 0'), findsNothing);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(430, 932);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('brand selection stays compact and avoids catalog repetition',
      (tester) async {
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
    Set<Brand>? changedBrands;
    Set<String>? changedTypes;
    bool? changedServesAll;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          brandsProvider.overrideWith((ref) async => brands.toList()),
        ],
        child: MaterialApp(
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
                  servesAllBrands: true,
                  onChanged: (selectedBrands, selectedTypes, servesAll) {
                    changedBrands = selectedBrands;
                    changedTypes = selectedTypes;
                    changedServesAll = servesAll;
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Todas las marcas'), findsOneWidget);
    expect(find.byKey(const Key('store-brand-logo-0')), findsOneWidget);
    expect(find.text('VER 25 MARCAS MÁS'), findsOneWidget);
    expect(find.text('Amplificación y Procesamiento'), findsNothing);
    expect(find.textContaining('Marca 9, Marca 10'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.byKey(const Key('toggle-all-brands')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('toggle-all-brands')));
    expect(changedBrands, isEmpty);
    expect(changedTypes, {'ORIGINAL', 'GENERIC'});
    expect(changedServesAll, isFalse);
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
