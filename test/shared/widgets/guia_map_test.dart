import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/theme/app_colors.dart';
import 'package:guiautomotriz_mobile/core/theme/app_icons.dart';
import 'package:guiautomotriz_mobile/shared/widgets/guia_google_map.dart';
import 'package:guiautomotriz_mobile/shared/widgets/guia_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  const point = LatLng(10.4619, -66.8336);

  Widget subject({required bool interactive}) {
    return MaterialApp(
      home: Scaffold(
        body: GuiaMap(
          point: point,
          interactive: interactive,
        ),
      ),
    );
  }

  testWidgets('uses the light branded marker in static map previews',
      (tester) async {
    await tester.pumpWidget(subject(interactive: false));

    final markerFinder = find.byKey(const Key('guia-map-branded-marker'));
    expect(markerFinder, findsOneWidget);
    expect(find.byIcon(AppIcons.location), findsOneWidget);

    final marker = tester.widget<Container>(markerFinder);
    final decoration = marker.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.primary);
    expect(decoration.shape, BoxShape.circle);

    final map = tester.widget<GuiaGoogleMap>(find.byType(GuiaGoogleMap));
    expect(map.markers, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the geographic marker on interactive maps',
      (tester) async {
    await tester.pumpWidget(subject(interactive: true));

    expect(
      find.byKey(const Key('guia-map-branded-marker')),
      findsNothing,
    );
    final map = tester.widget<GuiaGoogleMap>(find.byType(GuiaGoogleMap));
    expect(map.markers, hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
