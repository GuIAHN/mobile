import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/pages/home_page.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/service_type.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:guiautomotriz_mobile/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/home_item.dart';
import 'package:guiautomotriz_mobile/features/vehicles/presentation/providers/vehicle_providers.dart';

void main() {
  testWidgets('No search bar in Repuestos (shows form directly), search bar in Mecánicos with filter sheet', (WidgetTester tester) async {
    final handle = tester.binding.pipelineOwner.ensureSemantics();
    final container = ProviderContainer(
      overrides: [
        promosProvider.overrideWith((ref, type) async => []),
        homeItemsProvider.overrideWith((ref, type) async => []),
        userCarsProvider.overrideWith((ref) async => []),
        specialtiesProvider.overrideWith((ref) async => []),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: HomePage(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial service type is spareParts
    expect(container.read(selectedServiceTypeProvider), ServiceType.spareParts);
    
    expect(find.text('Buscar repuesto, marca o tienda...'), findsNothing);
    expect(find.text('CATEGORÍA DE REPUESTO *'), findsOneWidget);

    // Switch to Mecánicos
    await tester.tap(find.text('Mecánicos'));
    await tester.pumpAndSettle();

    expect(find.text('Buscar mecánico por nombre o especialidad...'), findsOneWidget);

    // Tap filters button
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();

    // Verify sheet items are displayed
    expect(find.text('Filtros de Búsqueda'), findsOneWidget);
    expect(find.text('ORDENAR POR'), findsOneWidget);
    expect(find.text('VALORACIÓN MÍNIMA'), findsOneWidget);
    expect(find.text('APLICAR FILTROS'), findsOneWidget);

    handle.dispose();
  });
}
