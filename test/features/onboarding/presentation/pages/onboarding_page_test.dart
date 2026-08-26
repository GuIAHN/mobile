import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:guiautomotriz_mobile/features/onboarding/presentation/widgets/ken_burns_background.dart';

void main() {
  Future<void> pumpLanding(
    WidgetTester tester, {
    required Size size,
    TextScaler textScaler = TextScaler.noScaling,
    double bottomSystemInset = 0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: true,
              textScaler: textScaler,
              padding: EdgeInsets.only(bottom: bottomSystemInset),
              viewPadding: EdgeInsets.only(bottom: bottomSystemInset),
            ),
            child: child!,
          ),
          home: const OnboardingPage(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('landing uses the login brand logo in the top-left corner',
      (tester) async {
    await pumpLanding(tester, size: const Size(377, 802));

    final logoFinder = find.byKey(const Key('onboarding-brand-logo'));
    final logo = tester.widget<Image>(logoFinder);

    expect(logo.image, const AssetImage('assets/images/logo.png'));
    expect(logo.semanticLabel, 'guIAutomotriz HN');
    expect(logo.width, 132);
    expect(tester.getTopLeft(logoFinder).dx, 20);
    expect(tester.getTopLeft(logoFinder).dy, lessThanOrEqualTo(48));
    expect(tester.getSize(find.byKey(const Key('onboarding-dot-0'))),
        const Size.square(48));
    expect(
      find.descendant(
        of: find.byType(KenBurnsBackground),
        matching: find.byType(Transform),
      ),
      findsNothing,
    );
  });

  testWidgets('compact landing keeps the logo and skip action on screen',
      (tester) async {
    await pumpLanding(
      tester,
      size: const Size(320, 568),
      textScaler: const TextScaler.linear(2),
    );

    expect(find.byKey(const Key('onboarding-brand-logo')), findsOneWidget);
    expect(find.text('SALTAR'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding-dot-2')));
    await tester.pump();

    expect(find.byKey(const Key('onboarding-continue')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('onboarding-continue'))).height,
      greaterThanOrEqualTo(48),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('large landing keeps the logo on the final slide',
      (tester) async {
    await pumpLanding(tester, size: const Size(430, 932));

    await tester.tap(find.byKey(const Key('onboarding-dot-2')));
    await tester.pump();

    expect(find.byKey(const Key('onboarding-brand-logo')), findsOneWidget);
    final continueFinder = find.byKey(const Key('onboarding-continue'));
    expect(continueFinder, findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
    expect(tester.getCenter(continueFinder).dx, 215);
    expect(tester.getSize(continueFinder).height, greaterThanOrEqualTo(48));
    expect(find.byType(FilledButton), findsNothing);
    expect(find.text('SALTAR'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Android navigation bar keeps footer above the system controls',
      (tester) async {
    const height = 802.0;
    const bottomSystemInset = 48.0;
    await pumpLanding(
      tester,
      size: const Size(377, height),
      bottomSystemInset: bottomSystemInset,
    );

    final footerControls = find.byKey(const Key('onboarding-footer-controls'));
    final firstDot = find.byKey(const Key('onboarding-dot-0'));

    expect(
      tester.getBottomRight(footerControls).dy,
      height - bottomSystemInset - 24,
    );
    expect(
      tester.getBottomRight(find.text('Encuentra Repuestos')).dy,
      lessThan(tester.getTopLeft(firstDot).dy),
    );
    expect(tester.takeException(), isNull);
  });
}
