import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/theme/app_icons.dart';
import 'package:guiautomotriz_mobile/features/provider_profile/domain/entities/store_catalog.dart';
import 'package:guiautomotriz_mobile/features/provider_profile/domain/entities/store_catalog_line.dart';
import 'package:guiautomotriz_mobile/features/provider_profile/presentation/providers/provider_profile_providers.dart';
import 'package:guiautomotriz_mobile/features/provider_profile/presentation/widgets/store_catalog_card.dart';

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
            child: StoreCatalogCard(),
          ),
        ),
      ),
    ),
  );
}

StoreCatalog _catalog({int brandCount = 34}) {
  return StoreCatalog(
    servesAllBrands: false,
    brands: List.generate(brandCount, (index) => 'Marca $index'),
    sparePartsTypes: const ['ORIGINAL', 'GENERIC'],
    subcategories: const [
      StoreCatalogLine(
        id: 'amplification',
        categoryId: 'audio',
        categoryName: 'Audio y multimedia',
        subcategoryName: 'Amplificación y Procesamiento',
      ),
      StoreCatalogLine(
        id: 'speakers',
        categoryId: 'audio',
        categoryName: 'Audio y multimedia',
        subcategoryName: 'Cornetas',
      ),
    ],
  );
}

void main() {
  testWidgets('shows a compact summary and opens the complete brand list',
      (tester) async {
    final catalog = _catalog();

    await tester.pumpWidget(
      _testApp(
        overrides: [
          storeCatalogProvider.overrideWith((ref) async => catalog),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('34 marcas'), findsOneWidget);
    expect(find.text('Original'), findsOneWidget);
    expect(find.text('Genérico'), findsOneWidget);
    expect(find.text('MARCAS QUE ATIENDES'), findsOneWidget);
    expect(find.text('CATEGORÍAS Y SUBCATEGORÍAS'), findsOneWidget);
    expect(find.text('Audio y multimedia'), findsOneWidget);
    expect(find.text('Amplificación y Procesamiento'), findsNothing);
    expect(find.text('Cornetas'), findsNothing);
    expect(find.text('Marca 0'), findsNothing);
    expect(find.text('Ver marcas'), findsOneWidget);
    expect(find.byIcon(AppIcons.audio), findsOneWidget);
    expect(
      find.byKey(const Key('store-category-audio')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Audio y multimedia, 2 subcategorías. Mostrar subcategorías',
      ),
      findsOneWidget,
    );

    final categoryToggle = find.byKey(const Key('store-category-toggle-audio'));
    expect(tester.getSize(categoryToggle).height, greaterThanOrEqualTo(48));
    await tester.tap(categoryToggle);
    await tester.pumpAndSettle();

    expect(find.text('Amplificación y Procesamiento'), findsOneWidget);
    expect(find.text('Cornetas'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Audio y multimedia, 2 subcategorías. Ocultar subcategorías',
      ),
      findsOneWidget,
    );

    await tester.tap(categoryToggle);
    await tester.pumpAndSettle();
    expect(find.text('Amplificación y Procesamiento'), findsNothing);
    expect(find.text('Cornetas'), findsNothing);
    expect(
      tester
          .getSize(
            find.byKey(
              const Key('store-catalog-brands'),
            ),
          )
          .height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(
      find.byKey(const Key('store-catalog-brands')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Marcas que atiendes'), findsOneWidget);
    expect(find.byKey(const Key('catalog-brands-list')), findsOneWidget);
    expect(find.text('Marca 0'), findsOneWidget);
    final closeSize = tester.getSize(
      find.byKey(const Key('close-catalog-details')),
    );
    expect(closeSize.width, greaterThanOrEqualTo(48));
    expect(closeSize.height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses semantic icons for different automotive categories',
      (tester) async {
    const catalog = StoreCatalog(
      servesAllBrands: true,
      sparePartsTypes: ['ORIGINAL'],
      subcategories: [
        StoreCatalogLine(
          id: 'engine',
          categoryId: 'motor',
          categoryName: 'Motor',
          subcategoryName: 'Componentes internos',
        ),
        StoreCatalogLine(
          id: 'pads',
          categoryId: 'brakes',
          categoryName: 'Frenos',
          subcategoryName: 'Pastillas de freno',
        ),
      ],
    );

    await tester.pumpWidget(
      _testApp(
        overrides: [
          storeCatalogProvider.overrideWith((ref) async => catalog),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(AppIcons.engine), findsOneWidget);
    expect(find.byIcon(AppIcons.brakes), findsOneWidget);
    expect(find.byIcon(AppIcons.services), findsNothing);
    expect(find.byKey(const Key('store-catalog-card')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows global catalog data even without subcategories',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        overrides: [
          storeCatalogProvider.overrideWith(
            (ref) async => const StoreCatalog(
              servesAllBrands: true,
              sparePartsTypes: ['ORIGINAL'],
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Todas las marcas'), findsOneWidget);
    expect(find.text('Original'), findsOneWidget);
    expect(
      find.text('Aún no has configurado tu catálogo de tienda.'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('preserves loading, empty and recoverable error states',
      (tester) async {
    final pending = Completer<StoreCatalog>();
    await tester.pumpWidget(
      _testApp(
        overrides: [
          storeCatalogProvider.overrideWith((ref) => pending.future),
        ],
      ),
    );
    await tester.pump();
    expect(
      find.bySemanticsLabel('Cargando catálogo de la tienda'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      _testApp(
        overrides: [
          storeCatalogProvider.overrideWith(
            (ref) async => const StoreCatalog(servesAllBrands: false),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Aún no has configurado tu catálogo de tienda.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      _testApp(
        overrides: [
          storeCatalogProvider.overrideWith(
            (ref) => Future<StoreCatalog>.error(
              Exception('technical secret'),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'No pudimos cargar el catálogo de la tienda. Inténtalo nuevamente.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('technical secret'), findsNothing);
    expect(find.byKey(const Key('retry-store-catalog')), findsOneWidget);
  });

  testWidgets('fits small and large phones with scaled text', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final catalog = _catalog(brandCount: 4);

    await tester.pumpWidget(
      _testApp(
        mediaQuery: const MediaQueryData(
          size: Size(320, 700),
          textScaler: TextScaler.linear(2),
        ),
        overrides: [
          storeCatalogProvider.overrideWith((ref) async => catalog),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final categoryToggle = find.byKey(const Key('store-category-toggle-audio'));
    await tester.ensureVisible(categoryToggle);
    await tester.tap(categoryToggle);
    await tester.pumpAndSettle();
    expect(find.text('Amplificación y Procesamiento'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final brandsCard = find.byKey(const Key('store-catalog-brands'));
    await tester.ensureVisible(brandsCard);
    await tester.tap(brandsCard);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('close-catalog-details')));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(430, 932);
    await tester.pumpWidget(
      _testApp(
        mediaQuery: const MediaQueryData(
          size: Size(430, 932),
          disableAnimations: true,
        ),
        overrides: [
          storeCatalogProvider.overrideWith((ref) async => catalog),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final largeBrandsCard = find.byKey(const Key('store-catalog-brands'));
    await tester.ensureVisible(largeBrandsCard);
    await tester.tap(largeBrandsCard);
    await tester.pump();
    expect(find.text('Marcas que atiendes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
