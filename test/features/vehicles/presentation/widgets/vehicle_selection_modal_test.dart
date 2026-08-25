import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/vehicles/domain/entities/brand.dart';
import 'package:guiautomotriz_mobile/features/vehicles/domain/entities/car_model.dart';
import 'package:guiautomotriz_mobile/features/vehicles/domain/entities/vehicle_variant.dart';
import 'package:guiautomotriz_mobile/features/vehicles/presentation/providers/vehicle_providers.dart';
import 'package:guiautomotriz_mobile/features/vehicles/presentation/widgets/vehicle_selection_modal.dart';

void main() {
  const brand = Brand(
    id: 'brand-1',
    name: 'Toyota',
    brandType: 'JAPONES',
  );
  const model = CarModel(
    id: 'model-1',
    brandId: 'brand-1',
    name: 'Corolla',
    vehicleType: 'CAR',
  );

  Widget buildSubject({
    required Future<List<VehicleVariant>> Function(Ref ref, String modelId)
        variantLoader,
    required ValueChanged<VehicleSelectionResult?> onResult,
    Future<VehicleVariant> Function(
            Ref ref, ({String modelId, int year}) input)?
        yearResolver,
    double textScale = 1,
    Size size = const Size(390, 844),
  }) {
    return ProviderScope(
      overrides: [
        brandModelsProvider.overrideWith(
          (ref, brandId) async => const [model],
        ),
        modelVariantsProvider.overrideWith(variantLoader),
        ensureModelYearVariantProvider.overrideWith(
          yearResolver ??
              (ref, input) async => VehicleVariant(
                    id: 'resolved-${input.year}',
                    modelId: input.modelId,
                    year: input.year,
                    motor: '',
                  ),
        ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    onResult(
                      await VehicleSelectionModal.show(
                        context,
                        initialBrand: brand,
                      ),
                    );
                  },
                  child: const Text('Abrir selector'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> selectYear(WidgetTester tester, int year) async {
    final currentYear = DateTime.now().year;
    final wheel = tester.widget<ListWheelScrollView>(
      find.byKey(const ValueKey('vehicle-year-wheel')),
    );
    (wheel.controller! as FixedExtentScrollController)
        .jumpToItem(currentYear + 1 - year);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-vehicle-year')));
    await tester.pumpAndSettle();
  }

  Future<void> openModelYears(WidgetTester tester) async {
    await tester.tap(find.text('Abrir selector'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Corolla'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the version even when a year has only one variant',
      (tester) async {
    VehicleSelectionResult? result;
    const variants = [
      VehicleVariant(
        id: 'variant-2023-1',
        modelId: 'model-1',
        year: 2023,
        motor: '1.8L',
      ),
      VehicleVariant(
        id: 'variant-2022',
        modelId: 'model-1',
        year: 2022,
        motor: '1.6L',
      ),
      VehicleVariant(
        id: 'variant-2023-2',
        modelId: 'model-1',
        year: 2023,
        motor: '2.0L',
      ),
    ];

    await tester.pumpWidget(
      buildSubject(
        variantLoader: (ref, modelId) async => variants,
        onResult: (value) => result = value,
      ),
    );
    await openModelYears(tester);

    expect(find.text('Año de Corolla'), findsOneWidget);
    expect(find.byKey(const ValueKey('vehicle-year-wheel')), findsOneWidget);
    expect(find.text('CONTINUAR'), findsOneWidget);

    await selectYear(tester, 2022);

    expect(find.text('Motor de Corolla 2022'), findsOneWidget);
    await tester
        .tap(find.byKey(const ValueKey('vehicle-variant-variant-2022')));
    await tester.pumpAndSettle();

    expect(result?.year, 2022);
    expect(result?.variantId, 'variant-2022');
    expect(result?.motor, '1.6L');
  });

  testWidgets('asks for the motor only when a year has multiple variants',
      (tester) async {
    VehicleSelectionResult? result;
    var loadCount = 0;
    const variants = [
      VehicleVariant(
        id: 'variant-1',
        modelId: 'model-1',
        year: 2023,
        motor: '1.8L',
      ),
      VehicleVariant(
        id: 'variant-2',
        modelId: 'model-1',
        year: 2023,
        motor: '2.0L',
      ),
    ];

    await tester.pumpWidget(
      buildSubject(
        variantLoader: (ref, modelId) async {
          loadCount++;
          return variants;
        },
        onResult: (value) => result = value,
      ),
    );
    await openModelYears(tester);
    await selectYear(tester, 2023);

    expect(find.text('Motor de Corolla 2023'), findsOneWidget);
    expect(find.text('1.8L'), findsOneWidget);
    expect(find.text('2.0L'), findsOneWidget);
    expect(loadCount, 1);

    await tester.tap(find.byKey(const ValueKey('vehicle-variant-variant-2')));
    await tester.pumpAndSettle();

    expect(result?.year, 2023);
    expect(result?.variantId, 'variant-2');
    expect(result?.motor, '2.0L');
  });

  testWidgets('registers a generic variant when the selected year has none',
      (tester) async {
    VehicleSelectionResult? result;
    ({String modelId, int year})? resolvedInput;

    await tester.pumpWidget(
      buildSubject(
        variantLoader: (ref, modelId) async => const [],
        yearResolver: (ref, input) async {
          resolvedInput = input;
          return VehicleVariant(
            id: 'generic-${input.year}',
            modelId: input.modelId,
            year: input.year,
            motor: '',
          );
        },
        onResult: (value) => result = value,
      ),
    );
    await openModelYears(tester);
    await tester.tap(find.byKey(const ValueKey('confirm-vehicle-year')));
    await tester.pumpAndSettle();

    expect(resolvedInput?.modelId, 'model-1');
    expect(resolvedInput?.year, DateTime.now().year);
    expect(result?.variantId, 'generic-${DateTime.now().year}');
  });

  testWidgets('supports empty data, large text, and accessible controls',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in const [Size(375, 667), Size(430, 932)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        buildSubject(
          variantLoader: (ref, modelId) async => const [],
          onResult: (_) {},
          textScale: 2,
          size: size,
        ),
      );
      await openModelYears(tester);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('vehicle-year-wheel')), findsOneWidget);
      expect(find.text('CONTINUAR'), findsOneWidget);
      expect(tester.getSize(find.byTooltip('Volver')).shortestSide, 48);
      expect(
        tester.getSize(find.byTooltip('Cerrar selector')).shortestSide,
        48,
      );

      await tester.tap(find.byTooltip('Cerrar selector'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('shows progress while the model variants are loading',
      (tester) async {
    final pendingVariants = Completer<List<VehicleVariant>>();

    await tester.pumpWidget(
      buildSubject(
        variantLoader: (ref, modelId) => pendingVariants.future,
        onResult: (_) {},
      ),
    );
    await tester.tap(find.text('Abrir selector'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Corolla'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pendingVariants.complete(const []);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('vehicle-year-wheel')), findsOneWidget);
  });

  testWidgets('shows a recoverable error when variants cannot be loaded',
      (tester) async {
    var loadCount = 0;

    await tester.pumpWidget(
      buildSubject(
        variantLoader: (ref, modelId) async {
          loadCount++;
          throw Exception('catalog unavailable');
        },
        onResult: (_) {},
      ),
    );
    await openModelYears(tester);

    expect(
      find.text('No pudimos cargar los datos de este modelo.'),
      findsOneWidget,
    );
    expect(find.text('REINTENTAR'), findsOneWidget);

    await tester.tap(find.text('REINTENTAR'));
    await tester.pump();
    await tester.pump();

    expect(loadCount, 2);
  });
}
