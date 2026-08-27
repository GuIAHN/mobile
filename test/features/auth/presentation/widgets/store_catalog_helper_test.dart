import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/widgets/store_catalog_helper.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/widgets/store_summary_step.dart';
import 'package:guiautomotriz_mobile/features/catalog/domain/entities/category.dart';
import 'package:guiautomotriz_mobile/features/vehicles/domain/entities/brand.dart';
import 'package:guiautomotriz_mobile/features/vehicles/presentation/providers/vehicle_providers.dart';

void main() {
  const brands = [
    Brand(id: 'ford', name: 'Ford', brandType: 'CAR'),
    Brand(id: 'toyota', name: 'Toyota', brandType: 'CAR'),
    Brand(id: 'chevrolet', name: 'Chevrolet', brandType: 'CAR'),
  ];

  Future<void> pumpCoverage(
    WidgetTester tester, {
    required Future<List<Brand>> Function(Ref ref) brandsOverride,
    double textScale = 1,
    Size size = const Size(390, 844),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [brandsProvider.overrideWith(brandsOverride)],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
            ),
            child: const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: _CoverageHarness(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('selects types and all brands directly on the step',
      (tester) async {
    await pumpCoverage(tester, brandsOverride: (ref) async => brands);
    await tester.pumpAndSettle();

    final grids = tester.widgetList<GridView>(find.byType(GridView));
    expect(grids, isNotEmpty);
    for (final grid in grids) {
      expect(grid.padding, EdgeInsets.zero);
    }

    await tester.tap(find.byKey(const Key('spare-part-type-ORIGINAL')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('toggle-all-brands')));
    await tester.pump();

    expect(find.byKey(const Key('store-brand-ford')), findsOneWidget);
    expect(find.byKey(const Key('store-brand-logo-ford')), findsOneWidget);
    expect(find.text('Toyota'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search filters brands without losing direct selection',
      (tester) async {
    await pumpCoverage(tester, brandsOverride: (ref) async => brands);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('store-brand-search')),
      'Ford',
    );
    await tester.pump();

    expect(find.byKey(const Key('store-brand-ford')), findsOneWidget);
    expect(find.text('Toyota'), findsNothing);

    await tester.tap(find.byKey(const Key('store-brand-ford')));
    await tester.pump();
    expect(find.byKey(const Key('store-brand-ford')), findsOneWidget);
  });

  testWidgets('long brand catalog is progressively disclosed', (tester) async {
    final manyBrands = List.generate(
      14,
      (index) => Brand(
        id: '$index',
        name: 'Marca $index',
        brandType: 'CAR',
      ),
    );
    await pumpCoverage(tester, brandsOverride: (ref) async => manyBrands);
    await tester.pumpAndSettle();

    expect(find.text('Marca 7'), findsOneWidget);
    expect(find.text('Marca 8'), findsOneWidget);
    expect(find.text('Marca 9'), findsNothing);
    expect(find.text('VER 5 MARCAS MÁS'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('show-all-store-brands')),
    );
    await tester.tap(find.byKey(const Key('show-all-store-brands')));
    await tester.pump();

    expect(find.text('Marca 13'), findsOneWidget);
    expect(find.text('MOSTRAR MENOS'), findsOneWidget);
  });

  testWidgets('brand catalog exposes loading and empty states', (tester) async {
    final pending = Completer<List<Brand>>();
    await pumpCoverage(tester, brandsOverride: (ref) => pending.future);
    await tester.pump();
    expect(find.text('Cargando marcas…'), findsOneWidget);

    pending.complete(const []);
    await tester.pumpAndSettle();
    expect(
      find.text('No hay marcas disponibles en este momento.'),
      findsOneWidget,
    );
  });

  testWidgets('brand catalog exposes a recoverable error', (tester) async {
    var attempts = 0;
    await pumpCoverage(
      tester,
      brandsOverride: (ref) async {
        attempts++;
        throw Exception('network failure');
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('No pudimos cargar las marcas.'), findsOneWidget);
    await tester.tap(find.text('REINTENTAR'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
  });

  testWidgets('selection grid fits a small phone with enlarged text',
      (tester) async {
    await pumpCoverage(
      tester,
      brandsOverride: (ref) async => brands,
      textScale: 2,
      size: const Size(320, 700),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('spare-part-type-ORIGINAL')), findsOneWidget);
    expect(
      find.byKey(const Key('spare-part-type-icon-ORIGINAL')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('toggle-all-brands')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _CoverageHarness extends StatefulWidget {
  const _CoverageHarness();

  @override
  State<_CoverageHarness> createState() => _CoverageHarnessState();
}

class _CoverageHarnessState extends State<_CoverageHarness> {
  late final LineaCatalogo _line;
  bool _servesAllBrands = false;

  @override
  void initState() {
    super.initState();
    _line = LineaCatalogo(
      category: const Category(id: 'pastillas', name: 'Pastillas'),
      parentCategory: const Category(id: 'frenos', name: 'Frenos'),
      brands: {},
      sparePartsTypes: {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return StoreSummaryStep(
      catalogo: [_line],
      servesAllBrands: _servesAllBrands,
      onChanged: (brands, types, servesAllBrands) {
        setState(() {
          _line.brands = brands;
          _line.sparePartsTypes = types;
          _servesAllBrands = servesAllBrands;
        });
      },
    );
  }
}
