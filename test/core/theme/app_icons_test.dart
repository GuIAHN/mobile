import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/theme/app_icons.dart';

void main() {
  test('semantic icons do not use the Material icon font', () {
    expect(AppIcons.services.fontFamily, isNot('MaterialIcons'));
    expect(AppIcons.location.fontFamily, AppIcons.services.fontFamily);
    expect(AppIcons.call.fontFamily, AppIcons.services.fontFamily);
    expect(AppIcons.socialContact.fontFamily, AppIcons.services.fontFamily);
    expect(AppIcons.otherContact.fontFamily, AppIcons.services.fontFamily);
    expect(AppIcons.engine.fontFamily, AppIcons.services.fontFamily);
    expect(AppIcons.brakes.fontFamily, AppIcons.services.fontFamily);
    expect(AppIcons.audio.fontFamily, AppIcons.services.fontFamily);
  });

  testWidgets('AppLineIcon renders the glyph without a decorative container',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppLineIcon(AppIcons.services),
          ),
        ),
      ),
    );

    final lineIcon = find.byType(AppLineIcon);
    expect(lineIcon, findsOneWidget);
    expect(find.descendant(of: lineIcon, matching: find.byType(Container)),
        findsNothing);
    expect(find.byIcon(AppIcons.services), findsOneWidget);
    expect(tester.getSize(lineIcon), const Size.square(AppIconSize.leading));
  });
}
