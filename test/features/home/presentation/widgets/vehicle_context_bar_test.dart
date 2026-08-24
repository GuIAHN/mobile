import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/provider_detail_widgets.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/vehicle_compatibility_bar.dart';

void main() {
  testWidgets('removes compatibility wording and keeps a 48dp vehicle action',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchVehicleProvider.overrideWith((ref) => null),
        ],
        child: const MaterialApp(
          home: Scaffold(body: VehicleCompatibilityBar()),
        ),
      ),
    );

    expect(find.textContaining('COMPATIBILIDAD'), findsNothing);
    expect(find.text('TU VEHÍCULO:'), findsOneWidget);
    final action = find.widgetWithText(TextButton, 'Elegir');
    expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
  });

  test('builds a WhatsApp inquiry with the selected vehicle', () {
    final message = ContactActions.providerInquiryMessage(
      vehicleDescription: 'Toyota Corolla (2020)',
    );
    final uri = ContactActions.whatsappUri(
      '9999-9999',
      message: message,
    );

    expect(uri.host, 'wa.me');
    expect(uri.path, '/50499999999');
    expect(uri.queryParameters['text'], contains('Toyota Corolla (2020)'));
    expect(uri.queryParameters['text'], contains('GuIA-HN'));
  });
}
