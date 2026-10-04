import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/theme/app_theme.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_conversation.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/widgets/store_contact_sheet.dart';

ChatConversation _details({String? phone = '+504 9999-0000'}) {
  return ChatConversation(
    id: 'conversation-1',
    threadId: 'request-1',
    participantName: 'Repuestos Central',
    lastMessage: '',
    unreadCount: 0,
    lastMessageAt: DateTime.utc(2026, 8, 24),
    offerStatus: 'BOUGHT',
    hasQuote: true,
    price: 1250,
    spareBrand: 'Alternador Denso',
    storePhone: phone,
    storeAddress: 'Boulevard Morazán, Tegucigalpa',
  );
}

Widget _subject(ChatConversation details, {double textScale = 1}) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: StoreContactSheet(details: details),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('keeps spare brand together with catch-all requester context',
      (tester) async {
    final details = ChatConversation(
      id: 'conversation-category',
      threadId: 'request-1',
      participantName: 'Repuestos Central',
      lastMessage: '',
      unreadCount: 0,
      lastMessageAt: DateTime.utc(2026, 9, 3),
      offerStatus: 'BOUGHT',
      hasQuote: true,
      price: 1250,
      spareBrand: 'Alternador Denso',
      subcategoryName: 'Nombre administrativo variable',
      subcategoryIsCatchAll: true,
      categoryName: 'Electricidad',
      storePhone: '+504 9999-0000',
    );

    await tester.pumpWidget(_subject(details));

    expect(
      find.text('Alternador Denso · Electricidad › No sé cuál exactamente'),
      findsOneWidget,
    );
    expect(find.text('Nombre administrativo variable'), findsNothing);
  });

  testWidgets('presents a clear purchase confirmation and one primary action',
      (tester) async {
    await tester.pumpWidget(_subject(_details()));

    expect(find.text('Compra registrada'), findsOneWidget);
    expect(find.text('Repuestos Central'), findsOneWidget);
    expect(find.text('Alternador Denso'), findsOneWidget);
    expect(find.text('Escribir por WhatsApp'), findsOneWidget);
    expect(
        find.byKey(const Key('store-contact-primary-action')), findsOneWidget);
    expect(find.textContaining('🎉'), findsNothing);
  });

  testWidgets('stays scrollable on a small phone with large text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_subject(_details(), textScale: 2));
    await tester.dragFrom(const Offset(160, 300), const Offset(0, -300));
    await tester.pump();

    expect(find.text('Cerrar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offers chat as the recovery path when no phone is public',
      (tester) async {
    await tester.pumpWidget(_subject(_details(phone: null)));

    expect(find.text('Volver al chat'), findsOneWidget);
    expect(find.textContaining('no tiene un teléfono público'), findsOneWidget);
  });
}
