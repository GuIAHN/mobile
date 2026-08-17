import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/shared/widgets/app_chip.dart';

void main() {
  const longLabel =
      'Afinamiento y Reprogramación de Computadoras (Tuning/Remap)';

  Widget buildSubject({
    Size size = const Size(375, 667),
    double textScale = 1,
    bool disableAnimations = false,
    bool horizontalList = false,
  }) {
    final chip = AppChip(
      label: longLabel,
      onTap: () {},
    );

    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: Scaffold(
          body: horizontalList
              ? SizedBox(
                  width: size.width,
                  height: 60,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [chip],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: size.width - 40,
                      child: Wrap(children: [chip]),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  testWidgets('wraps a long label within the available phone width',
      (tester) async {
    for (final size in const [Size(320, 568), Size(430, 932)]) {
      await tester.pumpWidget(buildSubject(size: size));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(AppChip)).width,
        lessThanOrEqualTo(size.width - 40),
      );
      expect(
        tester.getSize(find.byType(AppChip)).height,
        greaterThanOrEqualTo(48),
      );
    }
  });

  testWidgets('supports large text without a horizontal overflow',
      (tester) async {
    await tester.pumpWidget(buildSubject(textScale: 2));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AppChip)).width, lessThanOrEqualTo(335));
  });

  testWidgets('also works in an unbounded horizontal list', (tester) async {
    await tester.pumpWidget(buildSubject(horizontalList: true));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('disables its selection animation when reduced motion is on',
      (tester) async {
    await tester.pumpWidget(buildSubject(disableAnimations: true));

    final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    expect(container.duration, Duration.zero);
  });
}
