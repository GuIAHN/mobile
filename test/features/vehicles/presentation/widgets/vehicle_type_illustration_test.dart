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
    final image = tester.widget<Image>(find.byType(Image));
    final resized = image.image as ResizeImage;
    expect(
      (resized.imageProvider as AssetImage).assetName,
      'assets/images/vehicles/v3/sedan.webp',
    );
  });

  test('maps every vehicle family to a versioned generated asset', () {
    expect(
      VehicleTypeIllustration.getAssetPath('COMPACT'),
      'assets/images/vehicles/v3/compact.webp',
    );
    expect(
      VehicleTypeIllustration.getAssetPath('SPORT'),
      'assets/images/vehicles/v3/sport.webp',
    );
    expect(
      VehicleTypeIllustration.getAssetPath('SUV'),
      'assets/images/vehicles/v3/suv.webp',
    );
    expect(
      VehicleTypeIllustration.getAssetPath('PICKUP'),
      'assets/images/vehicles/v3/pickup.webp',
    );
    expect(
      VehicleTypeIllustration.getAssetPath('VAN'),
      'assets/images/vehicles/v3/van.webp',
    );
    expect(
      VehicleTypeIllustration.getAssetPath('MOTORCYCLE'),
      'assets/images/vehicles/v3/motorcycle.webp',
    );
  });
}
