import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/theme/app_colors.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_message.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/widgets/chat_message_bubble.dart';

void main() {
  ChatMessage message({
    MessageType type = MessageType.text,
    bool isFromMe = true,
    String content = '¿Todavía está disponible?',
  }) {
    return ChatMessage(
      id: 'message-1',
      conversationId: 'conversation-1',
      senderId: 'user-1',
      senderName: 'Elio',
      isFromMe: isFromMe,
      content: content,
      type: type,
      createdAt: DateTime(2026, 8, 24, 10, 42),
    );
  }

  Future<void> pumpBubble(WidgetTester tester, ChatMessage value) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: ChatMessageBubble(message: value),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('announces sender, content and time as one message',
      (tester) async {
    await pumpBubble(tester, message());

    expect(find.text('¿Todavía está disponible?'), findsOneWidget);
    expect(find.text('10:42 AM'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Tú: ¿Todavía está disponible?. 10:42 AM',
      ),
      findsOneWidget,
    );
  });

  testWidgets('uses the solid brand orange for outgoing text messages',
      (tester) async {
    await pumpBubble(tester, message());

    final bubble = tester.widget<DecoratedBox>(
      find.byKey(const Key('outgoing-message-bubble')),
    );
    final decoration = bubble.decoration as BoxDecoration;
    expect(decoration.color, AppColors.primary);
    expect(decoration.color, isNot(AppColors.primaryMuted));

    final text = tester.widget<Text>(find.text('¿Todavía está disponible?'));
    expect(text.style?.color, AppColors.textOnPrimary);
  });

  testWidgets('keeps incoming message text dark on its white surface',
      (tester) async {
    await pumpBubble(tester, message(isFromMe: false));

    final text = tester.widget<Text>(find.text('¿Todavía está disponible?'));
    expect(text.style?.color, AppColors.textPrimary);
  });

  testWidgets('opens a chat image in the zoom viewer', (tester) async {
    await pumpBubble(
      tester,
      message(
        type: MessageType.image,
        content: 'https://example.com/repuesto.jpg',
      ),
    );

    await tester.tap(find.bySemanticsLabel(
      'Tú envió una imagen a las 10:42 AM. Toca para ampliarla.',
    ));
    await tester.pump();

    expect(find.byTooltip('Cerrar imagen'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('wraps long messages on small phones with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.8),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(18),
            child: ChatMessageBubble(
              message: message(
                content:
                    'El repuesto está disponible y puedo enviarlo mañana por la mañana.',
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps system updates compact and readable', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const content = '¡El pedido fue marcado como entregado por la tienda!';
    await pumpBubble(
      tester,
      message(
        type: MessageType.system,
        isFromMe: false,
        content: content,
      ),
    );

    final richUpdate = find.textContaining(content, findRichText: true);
    expect(richUpdate, findsOneWidget);
    expect(
      find.textContaining('10:42 AM', findRichText: true),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    final systemSurface = find
        .ancestor(
          of: richUpdate,
          matching: find.byType(DecoratedBox),
        )
        .first;
    expect(
      tester.getSize(systemSurface).height,
      lessThan(84),
    );
  });

  testWidgets('renders a consumer cancellation as destructive, not success',
      (tester) async {
    const content = 'La compra fue cancelada por el consumidor';
    await pumpBubble(
      tester,
      message(
        type: MessageType.system,
        isFromMe: false,
        content: content,
      ),
    );

    final cancelled = tester.widget<DecoratedBox>(
      find.byKey(const Key('cancelled-system-message')),
    );
    expect((cancelled.decoration as BoxDecoration).color, AppColors.errorLight);
    expect(find.byKey(const Key('success-system-message')), findsNothing);
  });
}
