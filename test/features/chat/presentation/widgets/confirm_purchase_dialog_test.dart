import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_conversation.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/widgets/confirm_purchase_dialog.dart';

void main() {
  testWidgets('keeps spare brand together with catch-all requester context',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConfirmPurchaseDialog(
            details: ChatConversation(
              id: 'conversation-1',
              threadId: 'request-1',
              participantName: 'Repuestos Central',
              lastMessage: '',
              unreadCount: 0,
              lastMessageAt: DateTime.utc(2026, 9, 3),
              price: 125,
              spareBrand: 'Denso Premium',
              subcategoryName: 'Nombre administrativo variable',
              subcategoryIsCatchAll: true,
              categoryName: 'Electricidad',
            ),
          ),
        ),
      ),
    );

    expect(
      find.text('Denso Premium · Electricidad › No sé cuál exactamente'),
      findsOneWidget,
    );
    expect(find.text('Nombre administrativo variable'), findsNothing);
  });
}
