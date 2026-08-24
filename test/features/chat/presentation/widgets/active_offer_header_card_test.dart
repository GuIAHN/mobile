import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/utils/media_url.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_conversation.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/widgets/active_offer_header_card.dart';

void main() {
  ChatConversation offer(String status) => ChatConversation(
        id: 'conversation-1',
        threadId: 'request-1',
        participantName: 'Repuestos Central',
        lastMessage: '',
        unreadCount: 0,
        lastMessageAt: DateTime.utc(2026, 8, 22),
        offerId: 'offer-1',
        offerStatus: status,
        hasQuote: true,
        price: 125,
        storeRating: 4.5,
        storeReviewCount: 12,
      );

  Future<void> pumpCard(
    WidgetTester tester,
    ChatConversation details, {
    VoidCallback? onCancel,
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
          body: SingleChildScrollView(
            child: ActiveOfferHeaderCard(
              details: details,
              isStore: false,
              onCancelPressed: onCancel,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('places subtle cancellation above the store details action',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var pressed = false;
    await pumpCard(
      tester,
      offer('BOUGHT'),
      onCancel: () => pressed = true,
    );

    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Ver datos de la tienda'), findsOneWidget);
    expect(find.text('4.5 (12)'), findsOneWidget);

    final cancelTop = tester.getTopLeft(find.text('Cancelar')).dy;
    final detailsTop =
        tester.getTopLeft(find.text('Ver datos de la tienda')).dy;
    expect(cancelTop, lessThan(detailsTop));

    expect(
      find.ancestor(
        of: find.text('Cancelar'),
        matching: find.byType(TextButton),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.text('Ver datos de la tienda'),
        matching: find.byType(OutlinedButton),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancelar'));
    expect(pressed, isTrue);
  });

  testWidgets('renders cancelled as terminal and removes purchase actions',
      (tester) async {
    await pumpCard(
      tester,
      ChatConversation(
        id: 'conversation-1',
        threadId: 'request-1',
        participantName: 'Repuestos Central',
        lastMessage: '',
        unreadCount: 0,
        lastMessageAt: DateTime.utc(2026, 8, 22),
        offerId: 'offer-1',
        offerStatus: 'CANCELLED',
        hasQuote: true,
        price: 125,
        cancelSource: 'SYSTEM',
        cancelReason: 'Sin confirmación de entrega',
      ),
    );

    expect(find.text('COMPRA CANCELADA'), findsOneWidget);
    expect(find.text('Compra cancelada automáticamente'), findsOneWidget);
    expect(find.text('Sin confirmación de entrega'), findsOneWidget);
    expect(find.text('Cancelar'), findsNothing);
    expect(find.textContaining('Comprar Ahora'), findsNothing);
  });

  testWidgets('opens the offer image in the full-screen viewer',
      (tester) async {
    const backendImage = 'http://localhost:3000/uploads/offers/repuesto.jpg';
    await pumpCard(
      tester,
      ChatConversation(
        id: 'conversation-1',
        threadId: 'request-1',
        participantName: 'Repuestos Central',
        lastMessage: '',
        unreadCount: 0,
        lastMessageAt: DateTime.utc(2026, 8, 22),
        offerId: 'offer-1',
        offerStatus: 'SENT',
        hasQuote: true,
        price: 125,
        sparePhotoUrl: backendImage,
      ),
    );

    final photo = find.bySemanticsLabel('Ampliar imagen de la oferta');
    expect(photo, findsOneWidget);
    await tester.tap(photo);
    await tester.pump();

    expect(find.byTooltip('Cerrar imagen'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);

    final viewerImage = tester.widget<Image>(
      find.descendant(
        of: find.byType(InteractiveViewer),
        matching: find.byType(Image),
      ),
    );
    expect(
      (viewerImage.image as NetworkImage).url,
      resolveMediaUrl(backendImage),
    );
  });

  testWidgets('uses the backend total when delivery is included',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpCard(
      tester,
      ChatConversation(
        id: 'conversation-1',
        threadId: 'request-1',
        participantName: 'Repuestos Central',
        lastMessage: '',
        unreadCount: 0,
        lastMessageAt: DateTime.utc(2026, 8, 22),
        offerId: 'offer-1',
        offerStatus: 'SENT',
        hasQuote: true,
        price: 125,
        deliveryCost: 25,
        totalCost: 150,
        spareBrand: 'Pastillas de frenos',
        vehicleTitle: 'BMW 5 Series 1984',
      ),
    );

    expect(find.text(r'$150.00'), findsWidgets);
    expect(find.text('Total con delivery'), findsOneWidget);

    final priceTop = tester.getTopLeft(find.text(r'$150.00').first).dy;
    final titleTop = tester.getTopLeft(find.text('Pastillas de frenos')).dy;
    expect(
      (priceTop - titleTop).abs(),
      lessThan(56),
      reason: 'El precio debe compartir el bloque visual con la oferta.',
    );
  });

  testWidgets('remains usable on a small phone with scaled text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpCard(
      tester,
      ChatConversation(
        id: 'conversation-1',
        threadId: 'request-1',
        participantName: 'Repuestos Central',
        lastMessage: '',
        unreadCount: 0,
        lastMessageAt: DateTime.utc(2026, 8, 22),
        offerId: 'offer-1',
        offerStatus: 'BOUGHT',
        hasQuote: true,
        price: 125,
        spareBrand: 'Repuesto original de alto rendimiento',
        vehicleTitle: 'Toyota Land Cruiser 2026',
      ),
      textScale: 1.5,
    );

    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Ver datos de la tienda'), findsOneWidget);
  });
}
