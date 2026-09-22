import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/shared/widgets/app_phone_field.dart';

void main() {
  Widget subject(
    TextEditingController controller, {
    bool required = true,
    Size size = const Size(390, 844),
    TextScaler textScaler = TextScaler.noScaling,
    bool disableAnimations = false,
    bool enabled = true,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: textScaler,
          disableAnimations: disableAnimations,
        ),
        child: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                child: AppPhoneField(
                  label: 'NÚMERO DE TELÉFONO',
                  controller: controller,
                  required: required,
                  enabled: enabled,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('offers every prefix and composes seven subscriber digits',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(subject(controller));
    await tester.tap(find.byKey(const Key('phone-prefix-selector')));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    for (final prefix in const [
      '0412',
      '0414',
      '0424',
      '0416',
      '0426',
      '0422',
    ]) {
      expect(
        find.byKey(Key('phone-prefix-option-$prefix')),
        findsOneWidget,
      );
    }

    await tester.tap(find.byKey(const Key('phone-prefix-option-0426')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('phone-subscriber-input')),
      '12345678',
    );

    expect(controller.text, '04261234567');
    final subscriberField = tester.widget<TextField>(
      find.byKey(const Key('phone-subscriber-input')),
    );
    expect(subscriberField.controller!.text, '1234567');
  });

  testWidgets('shows a clear inline error for an incomplete required number',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(subject(controller));
    await tester.enterText(
      find.byKey(const Key('phone-subscriber-input')),
      '123',
    );
    await tester.pump();

    expect(
      find.text('Selecciona un prefijo y completa los 7 dígitos.'),
      findsOneWidget,
    );
  });

  testWidgets('allows the optional phone to remain empty', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: AppPhoneField(
              label: 'TELÉFONO (OPCIONAL)',
              controller: controller,
              required: false,
            ),
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isTrue);
    expect(controller.text, isEmpty);
  });

  testWidgets('disables both controls while the form is loading',
      (tester) async {
    final controller = TextEditingController(text: '04121234567');
    addTearDown(controller.dispose);

    await tester.pumpWidget(subject(controller, enabled: false));
    await tester.tap(find.byKey(const Key('phone-prefix-selector')));
    await tester.pump();

    expect(find.byType(BottomSheet), findsNothing);
    expect(
      find.byKey(const Key('phone-prefix-option-0412')),
      findsNothing,
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('phone-subscriber-input')),
          )
          .enabled,
      isFalse,
    );
    expect(controller.text, '04121234567');
  });

  testWidgets('adapts to representative phone widths and large text',
      (tester) async {
    final controller = TextEditingController(text: '04121234567');
    addTearDown(controller.dispose);

    for (final size in const [Size(320, 568), Size(430, 932)]) {
      await tester.pumpWidget(
        subject(
          controller,
          size: size,
          textScaler: const TextScaler.linear(2),
          disableAnimations: true,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull, reason: 'phone size $size');
      expect(
        tester.getSize(find.byKey(const Key('phone-prefix-selector'))).height,
        greaterThanOrEqualTo(48),
      );
    }
  });

  testWidgets('keeps the compact prefix menu usable on a small safe viewport',
      (tester) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);

    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      subject(
        controller,
        size: const Size(320, 568),
        textScaler: const TextScaler.linear(2),
        disableAnimations: true,
      ),
    );
    await tester.tap(find.byKey(const Key('phone-prefix-selector')));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    final firstOptionRect = tester.getRect(
      find.byKey(const Key('phone-prefix-option-0412')),
    );
    final lastOptionRect = tester.getRect(
      find.byKey(const Key('phone-prefix-option-0422')),
    );
    expect(firstOptionRect.width, lessThanOrEqualTo(144));
    expect(firstOptionRect.top, greaterThanOrEqualTo(0));
    expect(lastOptionRect.bottom, lessThanOrEqualTo(568));
    expect(tester.takeException(), isNull);
  });
}
