import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/widgets/store_profile_step.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/widgets/workshop_info_step.dart';

void main() {
  testWidgets('el RIF de tienda acepta como máximo 9 dígitos', (tester) async {
    final controllers = _Controllers();
    addTearDown(controllers.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StoreProfileStep(
              nombreController: controllers.name,
              emailController: controllers.email,
              telefonoController: controllers.phone,
              rifController: controllers.rif,
              hasDelivery: false,
              onHasDeliveryChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, '123456789'),
      '1234567890ABC',
    );

    expect(controllers.rif.text, '123456789');
  });

  testWidgets('el RIF de taller acepta como máximo 9 dígitos', (tester) async {
    final controllers = _Controllers();
    addTearDown(controllers.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: WorkshopInfoStep(
              nombreController: controllers.name,
              emailController: controllers.email,
              telefonoController: controllers.phone,
              rifController: controllers.rif,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, '123456789'),
      '1234567890ABC',
    );

    expect(controllers.rif.text, '123456789');
  });
}

class _Controllers {
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final rif = TextEditingController();

  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    rif.dispose();
  }
}
