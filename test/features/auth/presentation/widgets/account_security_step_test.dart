import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/auth/presentation/widgets/account_security_step.dart';

void main() {
  testWidgets('shows live password requirements and mismatch feedback',
      (tester) async {
    final password = TextEditingController();
    final confirmation = TextEditingController();
    addTearDown(password.dispose);
    addTearDown(confirmation.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AccountSecurityStep(
              passwordController: password,
              confirmPasswordController: confirmation,
            ),
          ),
        ),
      ),
    );

    expect(find.text('8 caracteres o más'), findsOneWidget);
    expect(find.text('Al menos un número'), findsOneWidget);
    expect(find.text('Al menos un símbolo'), findsOneWidget);
    expect(find.text('Ambas contraseñas coinciden'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Secure1!');
    await tester.enterText(find.byType(TextFormField).last, 'Different1!');
    await tester.pump();

    expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
  });

  testWidgets('explains that social registration needs no extra password',
      (tester) async {
    final password = TextEditingController();
    final confirmation = TextEditingController();
    addTearDown(password.dispose);
    addTearDown(confirmation.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AccountSecurityStep(
            passwordController: password,
            confirmPasswordController: confirmation,
            isSocial: true,
            socialProvider: 'GOOGLE',
          ),
        ),
      ),
    );

    expect(find.text('Tu cuenta está protegida'), findsOneWidget);
    expect(find.textContaining('Google'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('fits small and large phones with scaled text', (tester) async {
    final password = TextEditingController(text: 'Secure1!');
    final confirmation = TextEditingController(text: 'Secure1!');
    addTearDown(password.dispose);
    addTearDown(confirmation.dispose);

    for (final size in [const Size(320, 568), const Size(430, 932)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: const TextScaler.linear(1.6),
              disableAnimations: true,
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: AccountSecurityStep(
                  passwordController: password,
                  confirmPasswordController: confirmation,
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Ambas contraseñas coinciden'), findsOneWidget);
    }
  });
}
