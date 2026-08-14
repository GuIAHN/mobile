import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/spare_part_wizard/request_location_preview.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/spare_part_wizard/request_location_selection.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: 380, child: child),
      ),
    ),
  );
}

void main() {
  testWidgets('the empty card invites selection and is touch friendly',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _testApp(
        RequestLocationPreview(
          selection: null,
          onTap: () => taps++,
        ),
      ),
    );

    final card = find.byKey(const Key('request-location-preview'));
    expect(find.text('Elegir ubicación'), findsOneWidget);
    expect(tester.getSize(card).height, greaterThanOrEqualTo(96));
    expect(
      find.bySemanticsLabel('Elegir ubicación para esta solicitud'),
      findsOneWidget,
    );

    await tester.tap(card);
    expect(taps, 1);
  }, semanticsEnabled: true);

  testWidgets('the selected card shows its label and change action',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        RequestLocationPreview(
          selection: const RequestLocationSelection(
            latitude: 10.4806,
            longitude: -66.9036,
            label: 'Sabana Grande, Caracas',
            source: RequestLocationSource.mapTap,
          ),
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Sabana Grande, Caracas'), findsOneWidget);
    expect(find.text('Cambiar'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Cambiar ubicación para esta solicitud. '
        'Ubicación actual: Sabana Grande, Caracas',
      ),
      findsOneWidget,
    );
  }, semanticsEnabled: true);
}
