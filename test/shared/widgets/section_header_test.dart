import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/shared/widgets/section_header.dart';

void main() {
  testWidgets(
    'keeps a 48 dp section action target with scaled text',
    (tester) async {
      var taps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Talleres mejor valorados',
              action: SectionHeaderAction(
                label: 'Ver todos',
                onTap: () => taps++,
              ),
            ),
          ),
        ),
      );

      final action = find.bySemanticsLabel('Ver todos');
      expect(action, findsOneWidget);
      expect(find.text('Ver todos'), findsOneWidget);
      expect(tester.getSize(action).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(action).height, greaterThanOrEqualTo(48));

      await tester.tap(action);
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    },
    semanticsEnabled: true,
  );

  testWidgets('stacks its action on narrow layouts with large text',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(
              size: Size(335, 800),
              textScaler: TextScaler.linear(2),
            ),
            child: SizedBox(
              width: 335,
              child: SectionHeader(
                title: 'Mecánicos mejor valorados',
                icon: Icons.engineering_rounded,
                action: SectionHeaderAction(
                  label: 'Ver todos',
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Mecánicos mejor valorados'), findsOneWidget);
    expect(find.text('Ver todos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
