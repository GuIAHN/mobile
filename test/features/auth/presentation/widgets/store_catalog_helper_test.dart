import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/widgets/store_catalog_helper.dart';
import 'package:guiautomotriz_mobile/features/catalog/domain/entities/category.dart';
import 'package:guiautomotriz_mobile/features/vehicles/domain/entities/brand.dart';
import 'package:guiautomotriz_mobile/features/vehicles/presentation/providers/vehicle_providers.dart';

void main() {
  const brands = [
    Brand(id: 'ford', name: 'Ford', brandType: 'CAR'),
    Brand(id: 'toyota', name: 'Toyota', brandType: 'CAR'),
    Brand(id: 'chevrolet', name: 'Chevrolet', brandType: 'CAR'),
  ];

  Future<void> pumpSheet(
    WidgetTester tester, {
    double textScale = 1,
    Size size = const Size(390, 844),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          brandsProvider.overrideWith((ref) async => brands),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(textScale),
            ),
            child: const Scaffold(
              body: SheetMarcas(
                category: Category(id: 'motor', name: 'Motor'),
                seleccionInicial: {},
                typesInicial: {'ORIGINAL'},
                existia: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('selects and clears every available brand', (tester) async {
    await pumpSheet(tester);

    expect(find.text('Seleccionar todas (3)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('toggle-all-brands')));
    await tester.pump();

    expect(find.text('Quitar todas las marcas'), findsOneWidget);
    expect(find.text('Guardar (3 marcas)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('toggle-all-brands')));
    await tester.pump();

    expect(find.text('Seleccionar todas (3)'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
  });

  testWidgets('select all is not limited by the active search', (tester) async {
    await pumpSheet(tester);

    await tester.enterText(find.byType(TextField), 'Ford');
    await tester.pump();
    expect(find.text('Toyota'), findsNothing);

    await tester.tap(find.byKey(const Key('toggle-all-brands')));
    await tester.pump();

    expect(find.text('Guardar (3 marcas)'), findsOneWidget);
  });

  testWidgets('bulk action fits a small phone with enlarged text',
      (tester) async {
    await pumpSheet(
      tester,
      textScale: 2,
      size: const Size(320, 700),
    );

    expect(find.byKey(const Key('toggle-all-brands')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
