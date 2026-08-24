import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/user_role.dart';
import 'package:guiautomotriz_mobile/core/providers/current_user_provider.dart';
import 'package:guiautomotriz_mobile/core/services/socket_service.dart';
import 'package:guiautomotriz_mobile/core/theme/app_colors.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_conversation.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/repositories/chat_repository.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/pages/chat_conversation_page.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/providers/chat_providers.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/providers/reviews_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

class _MockSocketService extends Mock implements SocketService {}

void main() {
  testWidgets('store can open the decline flow from an inquiry chat',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _MockChatRepository();
    final socket = _MockSocketService();
    final details = ChatConversation(
      id: 'conversation-1',
      threadId: 'request-1',
      participantName: 'Carlos',
      lastMessage: '',
      unreadCount: 0,
      lastMessageAt: DateTime.utc(2026, 8, 24),
      offerId: 'offer-1',
      offerStatus: 'INQUIRY',
      searchMatchId: 'match-1',
      hasQuote: true,
      isInquiry: true,
      subcategoryName: 'Pastillas de freno',
    );

    when(() => repository.getConversationDetails('conversation-1'))
        .thenAnswer((_) async => Right(details));
    when(() => repository.getMessages('conversation-1'))
        .thenAnswer((_) async => const Right([]));
    when(() => repository.markAsRead('conversation-1'))
        .thenAnswer((_) async => const Right(null));
    when(() => socket.onSearchMatched).thenAnswer((_) => const Stream.empty());
    when(() => socket.onOfferUpdated).thenAnswer((_) => const Stream.empty());
    when(() => socket.onNotification).thenAnswer((_) => const Stream.empty());
    when(() => socket.onMessage).thenAnswer((_) => const Stream.empty());
    when(() => socket.onReconnect).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentRoleProvider.overrideWithValue(UserRole.store),
          chatRepositoryProvider.overrideWithValue(repository),
          socketServiceProvider.overrideWithValue(socket),
          handledStoreReviewProvider('conversation-1')
              .overrideWith((ref) async => false),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.5),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: const ChatConversationPage(
            conversationId: 'conversation-1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.text('CONSULTA ABIERTA'), findsOneWidget);
    expect(find.text('Cotizar'), findsOneWidget);
    expect(find.text('Declinar'), findsOneWidget);

    void expectCompactHorizontalActions() {
      final declineButton = find.byKey(const Key('decline-inquiry-button'));
      final quoteButton = find.byKey(const Key('quote-inquiry-button'));
      final declineRect = tester.getRect(declineButton);
      final quoteRect = tester.getRect(quoteButton);
      final declineWidget = tester.widget<OutlinedButton>(declineButton);
      final declineBorder = declineWidget.style?.side?.resolve(<WidgetState>{});

      expect(declineRect.center.dx, lessThan(quoteRect.center.dx));
      expect(
        (declineRect.center.dy - quoteRect.center.dy).abs(),
        lessThan(1),
      );
      expect(declineRect.height, greaterThanOrEqualTo(48));
      expect(quoteRect.height, greaterThanOrEqualTo(48));
      expect(declineBorder?.color, AppColors.border);
      expect(declineBorder?.width, 1.5);
      expect(
        tester.getSize(find.byKey(const Key('inquiry-actions-bar'))).height,
        lessThanOrEqualTo(60),
      );
    }

    expectCompactHorizontalActions();

    tester.view.physicalSize = const Size(430, 932);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expectCompactHorizontalActions();

    await tester.tap(find.text('Declinar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.text('Declinar solicitud'), findsOneWidget);
    expect(find.text('Sin stock'), findsOneWidget);

    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cotizar'));
    await tester.pumpAndSettle();

    expect(find.text('Enviar oferta'), findsOneWidget);
  });
}
