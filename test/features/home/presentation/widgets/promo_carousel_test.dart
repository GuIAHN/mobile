import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/promo.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/promo_carousel.dart';

void main() {
  group('externalAdUri', () {
    test('keeps complete backend URLs', () {
      expect(
        externalAdUri('https://example.com/oferta?id=7'),
        Uri.parse('https://example.com/oferta?id=7'),
      );
    });

    test('adds https when the backend URL has no scheme', () {
      expect(
        externalAdUri('www.example.com/oferta'),
        Uri.parse('https://www.example.com/oferta'),
      );
    });

    test('rejects empty and unsupported URLs', () {
      expect(externalAdUri('  '), isNull);
      expect(externalAdUri('javascript:alert(1)'), isNull);
    });
  });

  const promos = [
    Promo(
      title: 'Primer destacado',
      subtitle: 'Primera promoción',
      iconName: 'car',
      gradientColors: [0xFFF25C05, 0xFF3A86FF],
    ),
    Promo(
      title: 'Segundo destacado',
      subtitle: 'Segunda promoción',
      iconName: 'car',
      gradientColors: [0xFF3A86FF, 0xFFF25C05],
    ),
  ];

  Widget subject({required bool disableAnimations}) {
    return ProviderScope(
      child: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: PromoCarousel(promos: promos),
        ),
      ),
    );
  }

  double indicatorWidth(WidgetTester tester, Finder indicator) {
    return tester.widget<AnimatedContainer>(indicator).constraints!.maxWidth;
  }

  testWidgets('reduced motion keeps the first promo selected', (tester) async {
    await tester.pumpWidget(subject(disableAnimations: true));

    final firstIndicator = find.byKey(const Key('promo-indicator-0'));
    final secondIndicator = find.byKey(const Key('promo-indicator-1'));
    expect(indicatorWidth(tester, firstIndicator), 28);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 500));

    expect(indicatorWidth(tester, firstIndicator), 28);
    expect(indicatorWidth(tester, secondIndicator), 14);
  });

  testWidgets('normal motion advances to the next promo', (tester) async {
    await tester.pumpWidget(subject(disableAnimations: false));

    final firstIndicator = find.byKey(const Key('promo-indicator-0'));
    final secondIndicator = find.byKey(const Key('promo-indicator-1'));
    expect(indicatorWidth(tester, firstIndicator), 28);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 500));

    expect(indicatorWidth(tester, firstIndicator), 14);
    expect(indicatorWidth(tester, secondIndicator), 28);
  });
}
