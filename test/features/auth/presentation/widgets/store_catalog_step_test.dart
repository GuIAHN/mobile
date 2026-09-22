import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/widgets/store_catalog_helper.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/widgets/store_catalog_step.dart';
import 'package:guiautomotriz_mobile/features/catalog/domain/entities/category.dart';
import 'package:guiautomotriz_mobile/features/catalog/domain/entities/category_node.dart';
import 'package:guiautomotriz_mobile/features/catalog/presentation/providers/catalog_providers.dart';

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
  ];

  Widget buildSubject({
    List<LineaCatalogo>? catalogo,
    void Function(Category, Category)? onSubcategoryToggled,
  }) {
    return ProviderScope(
      overrides: [
        categoryTreeProvider.overrideWith((ref) async => categoryTree),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: StoreCatalogStep(
            catalogo: catalogo ?? const [],
            onSubcategoryToggled: onSubcategoryToggled ?? (_, __) {},
          ),
        ),
      ),
    );
  }

  testWidgets(
      'counts only the real subcategories, excluding the catch-all',
      (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    // "Frenos" tiene 2 hijos elegibles (Pastillas, Discos); "Otro" no cuenta.
    expect(find.text('2 disponibles'), findsOneWidget);
  });

  testWidgets(
      'never offers the catch-all option inside the category sheet',
      (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('store-category-frenos')));
    await tester.pumpAndSettle();

    expect(find.text('Pastillas de freno'), findsOneWidget);
    expect(find.text('Discos de freno'), findsOneWidget);
    expect(find.text('Otro'), findsNothing);
    expect(find.byKey(const Key('store-subcategory-frenos-otro')),
        findsNothing);
  });

  testWidgets(
      '"Seleccionar todas" never toggles the catch-all subcategory',
      (tester) async {
    final toggled = <String>[];
    await tester.pumpWidget(buildSubject(
      onSubcategoryToggled: (_, subcategory) => toggled.add(subcategory.id),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('store-category-frenos')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('toggle-all-store-subcategories')));
    await tester.pumpAndSettle();

    expect(toggled, containsAll(<String>['pastillas', 'discos']));
    expect(toggled, isNot(contains('frenos-otro')));
  });
}
