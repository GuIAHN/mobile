import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/theme/app_icons.dart';
import 'package:guiautomotriz_mobile/features/catalog/domain/entities/category.dart';
import 'package:guiautomotriz_mobile/features/catalog/domain/entities/category_node.dart';
import 'package:guiautomotriz_mobile/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/spare_part_wizard/category_subcategory_selector_sheet.dart';

void main() {
  const categoryTree = <CategoryNode>[
    CategoryNode(
      id: 'frenos',
      name: 'Frenos',
      children: <CategoryNode>[
        CategoryNode(
          id: 'frenos-otro',
          name: 'Otro',
          parentId: 'frenos',
          isCatchAll: true,
        ),
        CategoryNode(
          id: 'pastillas',
          name: 'Pastillas de freno',
          parentId: 'frenos',
        ),
        CategoryNode(
          id: 'discos',
          name: 'Discos de freno',
          parentId: 'frenos',
        ),
      ],
    ),
    CategoryNode(
      id: 'motor',
      name: 'Motor',
      children: <CategoryNode>[
        CategoryNode(
          id: 'filtro-aceite',
          name: 'Filtro de aceite',
          parentId: 'motor',
        ),
      ],
    ),
    CategoryNode(
      id: 'suspension',
      name: 'Suspensión',
      children: <CategoryNode>[
        CategoryNode(
          id: 'amortiguadores',
          name: 'Amortiguadores',
          parentId: 'suspension',
        ),
      ],
    ),
  ];

  Widget buildSubject({
    double textScale = 1,
    Size size = const Size(390, 844),
    Future<List<CategoryNode>> Function(Ref ref)? categoryLoader,
  }) {
    return ProviderScope(
      overrides: [
        categoryTreeProvider.overrideWith(
          categoryLoader ?? (ref) async => categoryTree,
        ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: const Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: CategorySubcategorySelectorSheet(),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('uses the compact header with local category search',
      (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(milliseconds: 360));
    await tester.pumpAndSettle();

    expect(find.text('CATÁLOGO DE PIEZAS'), findsOneWidget);
    expect(find.text('Busca tu repuesto'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('¿Qué tipo de repuesto'), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsNothing);
    expect(tester.getSize(find.byTooltip('Volver')).shortestSide, 48);
    expect(tester.getSize(find.byTooltip('Cerrar selector')).shortestSide, 48);
  });

  testWidgets(
      'searches locally and reuses one category-tree request per session',
      (tester) async {
    var categoryLoads = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryTreeProvider.overrideWith((ref) async {
            categoryLoads++;
            return categoryTree;
          }),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => CategorySubcategorySelectorSheet.show(
                    context,
                  ),
                  child: const Text('Abrir selector'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir selector'));
    await tester.pump(const Duration(milliseconds: 360));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'pas');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'pastillas');
    await tester.pumpAndSettle();
    expect(find.text('Pastillas de freno'), findsOneWidget);
    expect(categoryLoads, 1);

    await tester.tap(find.byTooltip('Cerrar selector'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir selector'));
    await tester.pump(const Duration(milliseconds: 360));
    await tester.pumpAndSettle();

    expect(categoryLoads, 1);
  });

  testWidgets('matches category breadcrumbs without requiring accents',
      (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(milliseconds: 360));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'suspension');
    await tester.pumpAndSettle();

    expect(find.text('Amortiguadores'), findsOneWidget);
    expect(find.textContaining('Suspensión'), findsOneWidget);
  });

  testWidgets('navigates from parent categories to a focused child list',
      (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(milliseconds: 360));
    await tester.pumpAndSettle();

    expect(find.text('Pastillas de freno'), findsNothing);
    expect(find.byKey(const ValueKey('category-root-motor')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('category-root-frenos')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('category-view-frenos')), findsOneWidget);
    expect(find.text('Pastillas de freno'), findsOneWidget);
    expect(find.byKey(const ValueKey('category-root-motor')), findsNothing);
    expect(find.text('Frenos'), findsOneWidget);
    expect(find.text('No encuentro la pieza en Frenos'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'pieza inexistente');
    await tester.pumpAndSettle();
    expect(find.text('No encuentro la pieza en Frenos'), findsOneWidget);
    await tester.tap(find.byTooltip('Limpiar búsqueda'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('category-root-frenos')), findsOneWidget);
    expect(find.byKey(const ValueKey('category-root-motor')), findsOneWidget);
    expect(find.text('Pastillas de freno'), findsNothing);
    expect(find.text('No encuentro la pieza en Frenos'), findsNothing);
  });

  testWidgets('uses AppIcons at root and compact dots for children',
      (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(milliseconds: 360));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('category-root-frenos')),
        matching: find.byIcon(AppIcons.brakes),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('category-root-frenos')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('category-node-pastillas')),
        matching: find.byType(Icon),
      ),
      findsNothing,
    );

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('category-root-motor')),
        matching: find.byIcon(AppIcons.engine),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('category-root-motor')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('category-node-filtro-aceite')),
        matching: find.byType(Icon),
      ),
      findsNothing,
    );
  });

  testWidgets('keeps the selector usable on small and large phones',
      (tester) async {
    for (final size in const [Size(375, 667), Size(430, 932)]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpWidget(buildSubject(textScale: 2, size: size));
      await tester.pump(const Duration(milliseconds: 360));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Busca tu repuesto'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('category-root-frenos')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('category-root-frenos')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('No encuentro la pieza en Frenos'), findsOneWidget);
    }
  });

  testWidgets('opens an existing selection inside its parent category',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryTreeProvider.overrideWith((ref) async => categoryTree),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(390, 844)),
            child: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: CategorySubcategorySelectorSheet(
                  initialCategory: Category(id: 'frenos', name: 'Frenos'),
                  initialSubcategory: Category(
                    id: 'pastillas',
                    name: 'Pastillas de freno',
                    parentId: 'frenos',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 360));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('category-view-frenos')), findsOneWidget);
    expect(find.text('No encuentro la pieza en Frenos'), findsOneWidget);
    expect(find.byKey(const ValueKey('category-root-motor')), findsNothing);
  });

  testWidgets('returns the root category and selected leaf', (tester) async {
    CategorySubcategoryResult? selection;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryTreeProvider.overrideWith((ref) async => categoryTree),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    selection =
                        await CategorySubcategorySelectorSheet.show(context);
                  },
                  child: const Text('Abrir selector'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir selector'));
    await tester.pump();
    expect(find.byKey(const Key('category-sheet-shell')), findsOneWidget);
    expect(find.byKey(const Key('category-sheet-warmup')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 360));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('category-sheet-content')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('category-root-frenos')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pastillas de freno'));
    await tester.pumpAndSettle();

    expect(selection?.category.id, 'frenos');
    expect(selection?.subcategory.id, 'pastillas');
  });

  testWidgets('renders loading, empty, and recoverable error states',
      (tester) async {
    final pendingCategories = Completer<List<CategoryNode>>();
    await tester.pumpWidget(
      buildSubject(categoryLoader: (ref) => pendingCategories.future),
    );
    await tester.pump();
    expect(find.byKey(const Key('category-sheet-warmup')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 360));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pendingCategories.complete(const <CategoryNode>[]);
    await tester.pumpAndSettle();
    expect(
      find.text('No hay categorías disponibles en este momento.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      buildSubject(
        categoryLoader: (ref) => Future<List<CategoryNode>>.error(
          Exception('backend secret'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 360));
    await tester.pumpAndSettle();

    expect(find.text('No pudimos cargar las categorías.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.textContaining('backend secret'), findsNothing);
  });

  testWidgets(
      'offers the root catch-all as a contextual footer action and returns it',
      (tester) async {
    CategorySubcategoryResult? selection;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryTreeProvider.overrideWith((ref) async => categoryTree),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    selection =
                        await CategorySubcategorySelectorSheet.show(context);
                  },
                  child: const Text('Abrir selector'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir selector'));
    await tester.pump(const Duration(milliseconds: 360));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('category-root-frenos')));
    await tester.pumpAndSettle();

    // It is a stable fallback action, separate from the actual pieces.
    expect(find.text('No encuentro la pieza en Frenos'), findsOneWidget);
    expect(find.text('No sé cuál exactamente'), findsNothing);
    expect(find.text('Otro'), findsNothing);
    expect(
      find.byKey(const ValueKey('category-node-frenos-otro')),
      findsNothing,
    );

    await tester.tap(find.text('No encuentro la pieza en Frenos'));
    await tester.pumpAndSettle();

    expect(selection?.category.id, 'frenos');
    expect(selection?.subcategory.id, 'frenos-otro');
    expect(selection?.subcategory.isCatchAll, isTrue);
  });

  testWidgets('keeps the catch-all out of search results', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pump(const Duration(milliseconds: 360));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'otro');
    await tester.pumpAndSettle();

    // Searching the catch-all's stored name must not return one identical
    // row per root - the requester picks it inside a category, on purpose.
    expect(find.text('No sé cuál exactamente'), findsNothing);
    expect(
      find.textContaining('Abre la categoría del sistema'),
      findsOneWidget,
    );
  });
}
