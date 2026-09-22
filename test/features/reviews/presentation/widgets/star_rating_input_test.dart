import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/widgets/star_rating_input.dart';

void main() {
  testWidgets('requires an explicit 1 to 5 selection with 48 dp targets',
      (tester) async {
    var rating = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StarRatingInput(
            rating: rating,
            onChanged: (value) => rating = value,
          ),
        ),
      ),
    );

    final targets = find.byType(SizedBox);
    expect(
      tester.widgetList<SizedBox>(targets).where((box) => box.width == 48),
      hasLength(5),
    );
    await tester.tap(find.bySemanticsLabel('4 estrellas'));
    expect(rating, 4);
  });

  testWidgets('uses a compact row when the rating is read only',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 228.3,
            child: StarRatingInput(
              rating: 4,
              readOnly: true,
              size: 16,
            ),
          ),
        ),
      ),
    );

    final rating = find.bySemanticsLabel('4 de 5 estrellas');
    expect(rating, findsOneWidget);
    expect(tester.getSize(rating).width, lessThanOrEqualTo(228.3));
    expect(tester.takeException(), isNull);
  });
}
