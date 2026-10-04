import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/theme/app_colors.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/widgets/chat_message_composer.dart';

void main() {
  late TextEditingController controller;
  late FocusNode focusNode;

  setUp(() {
    controller = TextEditingController();
    focusNode = FocusNode();
  });

  tearDown(() {
    controller.dispose();
    focusNode.dispose();
  });

  Future<void> pumpComposer(
    WidgetTester tester, {
    required bool canSend,
    bool isSending = false,
    VoidCallback? onSend,
    double textScale = 1,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ChatMessageComposer(
              controller: controller,
              focusNode: focusNode,
              canSend: canSend,
              isSending: isSending,
              onSend: onSend ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('uses a pill input and a separate circular send action',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpComposer(tester, canSend: false);

    expect(
      tester.widget(find.byKey(const ValueKey('chat-composer-shell'))),
      isA<Padding>(),
      reason: 'El compositor no debe agregar una franja de fondo.',
    );
    final input = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('chat-composer-input')),
    );
    final send = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('chat-composer-send')),
    );
    final inputDecoration = input.decoration! as BoxDecoration;
    final sendDecoration = send.decoration! as BoxDecoration;

    expect(inputDecoration.borderRadius, BorderRadius.circular(999));
    expect(
      inputDecoration.boxShadow,
      isEmpty,
      reason: 'La sombra inferior se percibe como un segundo borde.',
    );
    expect(sendDecoration.shape, BoxShape.circle);
    expect(sendDecoration.color, AppColors.primaryMuted);
    expect(
      tester.getSize(find.byKey(const ValueKey('chat-composer-send'))),
      const Size.square(56),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('chat-composer-input'))).height,
      greaterThanOrEqualTo(56),
    );
  });

  testWidgets('activates the orange send button when the message is ready',
      (tester) async {
    var sent = false;
    await pumpComposer(
      tester,
      canSend: true,
      onSend: () => sent = true,
    );

    final send = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('chat-composer-send')),
    );
    final decoration = send.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.primary);

    await tester.tap(find.byTooltip('Enviar mensaje'));
    expect(sent, isTrue);
  });

  testWidgets('keeps the composer usable with large text on a small phone',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpComposer(tester, canSend: true, textScale: 1.8);

    expect(find.text('Escribe un mensaje…'), findsOneWidget);
    expect(find.byTooltip('Enviar mensaje'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dismisses the keyboard by tapping outside the input',
      (tester) async {
    await pumpComposer(tester, canSend: false);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tapAt(const Offset(12, 12));
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
  });
}
