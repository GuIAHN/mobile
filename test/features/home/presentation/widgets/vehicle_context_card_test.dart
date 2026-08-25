import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/theme/app_colors.dart';
import 'package:guiautomotriz_mobile/core/theme/app_icons.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/vehicle_context_card.dart';
import 'package:guiautomotriz_mobile/features/vehicles/domain/entities/user_car.dart';

Widget _subject({
  UserCar? vehicle,
  Size size = const Size(375, 812),
  double textScale = 1,
}) {
  return ProviderScope(
    overrides: [
      searchVehicleProvider.overrideWith((ref) => vehicle),
    ],
    child: MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: VehicleContextCard()),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('uses the design system for the empty vehicle state',
      (tester) async {
    await tester.pumpWidget(_subject());

    expect(find.byIcon(AppIcons.vehicle), findsOneWidget);
    expect(find.text('TU VEHÍCULO'), findsNothing);
    expect(find.text('Selecciona el vehículo'), findsOneWidget);
    expect(find.textContaining('Lo incluiremos'), findsNothing);
    expect(find.textContaining('COMPATIBILIDAD'), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(
      tester
          .widget<Material>(find.byKey(const Key('vehicle-context-card')))
          .color,
      AppColors.surface,
    );
    expect(
      tester.widget<AppLineIcon>(find.byType(AppLineIcon)).size,
      AppIconSize.feature,
    );
    expect(
      tester.getSize(find.byKey(const Key('vehicle-context-action'))).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.byKey(const Key('vehicle-context-card'))).height,
      lessThanOrEqualTo(64),
    );
  });

  testWidgets('shows the full vehicle and adapts to large text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _subject(
        vehicle: const UserCar(
          id: 'car-1',
          brand: 'Toyota',
          model: 'Corolla',
          year: 2022,
          version: 'XLE 1.8L',
        ),
        size: const Size(320, 720),
        textScale: 2,
      ),
    );

    expect(find.text('Toyota Corolla'), findsOneWidget);
    expect(find.text('Año 2022 · Versión XLE 1.8L'), findsOneWidget);
    expect(find.text('Elegir'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
