import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

StoreCatalogLine _catalogLine({int brandCount = 34}) {
  return StoreCatalogLine(
    id: 'amplification',
    categoryName: 'Amplificación y Procesamiento',
    servesAllBrands: false,
    brands: List.generate(brandCount, (index) => 'Marca $index'),
    sparePartsTypes: const ['ORIGINAL', 'GENERIC'],
  );
}

void main() {
  testWidgets('shows a compact summary and opens the complete brand list',
      (tester) async {
    final line = _catalogLine();

    await tester.pumpWidget(
      _testApp(
        overrides: [
          storeCatalogProvider.overrideWith((ref) async => [line]),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('34 marcas'), findsOneWidget);
    expect(find.text('Original · Genérico'), findsOneWidget);
    expect(find.text('Marca 0'), findsNothing);
    expect(find.text('Ver marcas'), findsOneWidget);
    expect(
      tester
          .getSize(
            find.byKey(
              const ValueKey('store-catalog-line-amplification'),
            ),
          )
          .height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(
      find.byKey(const ValueKey('store-catalog-line-amplification')),
    );
    await tester.pumpAndSettle();

    expect(find.text('MARCAS'), findsOneWidget);
    expect(find.byKey(const Key('catalog-brands-list')), findsOneWidget);
    expect(find.text('Marca 0'), findsOneWidget);
    final closeSize = tester.getSize(
      find.byKey(const Key('close-catalog-details')),
    );
    expect(closeSize.width, greaterThanOrEqualTo(48));
    expect(closeSize.height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('preserves loading, empty and recoverable error states',
      (tester) async {
    final pending = Completer<List<StoreCatalogLine>>();
    await tester.pumpWidget(
      _testApp(
        overrides: [
          storeCatalogProvider.overrideWith((ref) => pending.future),
        ],
      ),
    );
    await tester.pump();
    expect(find.bySemanticsLabel('Cargando línea de venta'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      _testApp(
        overrides: [
          storeCatalogProvider.overrideWith((ref) async => const []),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Aún no has configurado tu línea de venta.'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      _testApp(
        overrides: [
          storeCatalogProvider.overrideWith(
            (ref) => Future<List<StoreCatalogLine>>.error(
              Exception('technical secret'),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'No pudimos cargar tu línea de venta. Inténtalo nuevamente.',
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
    final line = _catalogLine(brandCount: 4);

    await tester.pumpWidget(
      _testApp(
        mediaQuery: const MediaQueryData(
          size: Size(320, 700),
          textScaler: TextScaler.linear(2),
        ),
        overrides: [
          storeCatalogProvider.overrideWith((ref) async => [line]),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byKey(const ValueKey('store-catalog-line-amplification')),
    );
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
          storeCatalogProvider.overrideWith((ref) async => [line]),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byKey(const ValueKey('store-catalog-line-amplification')),
    );
    await tester.pump();
    expect(find.text('MARCAS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
