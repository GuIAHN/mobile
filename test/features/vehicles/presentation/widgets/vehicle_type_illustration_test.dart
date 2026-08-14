import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/vehicles/presentation/widgets/_atoms/vehicle_type_illustration.dart';

void main() {
  testWidgets('uses bounded layout width when requested width is infinite',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 220,
            height: 130,
            child: VehicleTypeIllustration(
              vehicleType: 'CAR',
              width: double.infinity,
              height: double.infinity,
              showBackground: false,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Image), findsOneWidget);
  });
}
