import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/entities/my_review_status.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/providers/reviews_providers.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/widgets/write_review_bottom_sheet.dart';

void main() {
  testWidgets('blocks submission until stars are selected', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myReviewProvider.overrideWith(
            (ref, targetId) async => const MyReviewStatus(hasReviewed: false),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: WriteReviewBottomSheet(
              targetId: 'mechanic-user-1',
              providerName: 'Mecánico Centro',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    var button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'PUBLICAR RESEÑA'),
    );
    expect(button.onPressed, isNull);

    await tester.tap(find.bySemanticsLabel('5 estrellas'));
    await tester.pump();
    button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'PUBLICAR RESEÑA'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('fits a small safe area with 200 percent text', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myReviewProvider.overrideWith(
            (ref, targetId) async => const MyReviewStatus(hasReviewed: false),
          ),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(320, 640),
              padding: EdgeInsets.only(bottom: 24),
              textScaler: TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: Scaffold(
              body: WriteReviewBottomSheet(
                targetId: 'mechanic-user-1',
                providerName: 'Mecánico con un nombre bastante largo',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('PUBLICAR RESEÑA'), findsOneWidget);
  });
}
