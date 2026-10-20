import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/entities/my_review_status.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/pages/review_editor_sheet.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/providers/reviews_providers.dart';

void main() {
  testWidgets('can retry a failed review load without a parent Material',
      (tester) async {
    final response = Completer<MyReviewStatus>();
    var retry = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myReviewProvider.overrideWith((ref, key) {
            if (retry) {
              return Future.value(const MyReviewStatus(hasReviewed: false));
            }
            return response.future;
          }),
        ],
        child: const MaterialApp(
          home: ReviewEditorSheet(
            targetId: 'mechanic-1',
            providerName: 'Mecánico Centro',
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);

    response.completeError(StateError('No connection'));
    await tester.pumpAndSettle();
    expect(find.text('No pudimos cargar tu valoración'), findsOneWidget);
    expect(tester.takeException(), isNull);

    retry = true;
    final retryButton = find.widgetWithText(TextButton, 'Reintentar');
    expect(tester.getSize(retryButton).height, greaterThanOrEqualTo(48));
    await tester.tap(retryButton);
    await tester.pumpAndSettle();
    expect(find.text('Selecciona de 1 a 5 estrellas'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 430.0]) {
    testWidgets('can rate from a route without Material at width $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myReviewProvider.overrideWith(
              (ref, key) async => const MyReviewStatus(hasReviewed: false),
            ),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(bottom: 34),
                textScaler: TextScaler.linear(width == 320 ? 2 : 1),
                disableAnimations: true,
              ),
              child: child!,
            ),
            // Like the transparent review-editor route, this has no Scaffold
            // or modal BottomSheet supplying a Material ancestor.
            home: const ReviewEditorSheet(
              targetId: 'mechanic-1',
              providerName: 'Mecánico con un nombre bastante largo',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      final stars = find.byType(InkResponse);
      expect(stars, findsNWidgets(5));
      for (final star in stars.evaluate()) {
        expect(tester.getSize(find.byWidget(star.widget)), const Size(48, 48));
      }

      await tester.tap(find.bySemanticsLabel('4 estrellas'));
      await tester.pump();
      expect(find.text('4 de 5 estrellas'), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull,
      );
      expect(
        tester
            .widgetList<AnimatedScale>(find.byType(AnimatedScale))
            .every((scale) => scale.duration == Duration.zero),
        isTrue,
      );
      await tester.ensureVisible(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'Buen servicio');
      await tester.ensureVisible(find.byType(ElevatedButton));
      final buttonBottom =
          tester.getBottomRight(find.byType(ElevatedButton)).dy;
      expect(buttonBottom, lessThanOrEqualTo(932 - 34));
      expect(tester.takeException(), isNull);
    });
  }
}
