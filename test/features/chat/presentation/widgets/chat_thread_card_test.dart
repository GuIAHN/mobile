import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/service_type.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_thread.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/repositories/chat_repository.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/providers/chat_providers.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/widgets/chat_thread_card.dart';
import 'package:mocktail/mocktail.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

void main() {
  testWidgets('presents a catch-all store label with its root path',
      (tester) async {
    final thread = ChatThread(
      id: 'request-1',
      title: 'Toyota Corolla',
      requestType: ServiceType.spareParts,
      unreadCount: 0,
      conversationCount: 0,
      lastActivityAt: DateTime.utc(2026, 8, 24),
      searchMatchId: 'match-1',
      matchState: 'PENDING',
      subcategory: 'Otro',
      subcategoryIsCatchAll: true,
      categoryName: 'Electricidad',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChatThreadCard(
                thread: thread,
                onTap: () {},
                onViewDetail: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.text('Electricidad › Sin categoría exacta — ver descripción'),
      findsOneWidget,
    );
    expect(find.text('Otro'), findsNothing);
    expect(
      find.bySemanticsLabel(
        RegExp(r'Electricidad › Sin categoría exacta — ver descripción'),
      ),
      findsOneWidget,
    );
  }, semanticsEnabled: true);

  testWidgets('the no-stock flow declines the exact store match once',
      (tester) async {
    final repository = _MockChatRepository();
    when(() => repository.declineMatch('match-1', 'SIN_STOCK')).thenAnswer(
      (_) async => const Right(null),
    );
    final thread = ChatThread(
      id: 'request-1',
      title: 'Toyota Corolla',
      requestType: ServiceType.spareParts,
      unreadCount: 0,
      conversationCount: 0,
      lastActivityAt: DateTime.utc(2026, 8, 24),
      searchMatchId: 'match-1',
      matchState: 'PENDING',
      subcategory: 'Pastillas de freno',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChatThreadCard(
                thread: thread,
                onTap: () {},
                onViewDetail: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('No puedo atenderla'));
    await tester.pumpAndSettle();
    expect(find.text('Sin stock'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Declinar'));
    await tester.pumpAndSettle();

    verify(() => repository.declineMatch('match-1', 'SIN_STOCK')).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending request opens its detail instead of quoting from card',
      (tester) async {
    var detailTapCount = 0;
    var cardTapCount = 0;
    final thread = ChatThread(
      id: 'request-1',
      title: 'Toyota Corolla',
      requestType: ServiceType.spareParts,
      unreadCount: 0,
      conversationCount: 0,
      lastActivityAt: DateTime.utc(2026, 8, 24),
      searchMatchId: 'match-1',
      matchState: 'PENDING',
      subcategory: 'Pastillas de freno',
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChatThreadCard(
                thread: thread,
                onTap: () => cardTapCount++,
                onViewDetail: () => detailTapCount++,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Ver detalle'), findsOneWidget);
    expect(find.text('Cotizar ahora'), findsNothing);

    await tester.tap(find.byKey(const Key('view-request-detail-button')));
    await tester.pump();

    expect(detailTapCount, 1);
    expect(cardTapCount, 0);
  });
}
