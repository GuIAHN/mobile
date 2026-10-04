import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guiautomotriz_mobile/core/router/route_names.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/widgets/provider_reviews_button.dart';

void main() {
  testWidgets('presents reviews clearly and opens the public reviews route',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(24),
              child: ProviderReviewsButton(
                targetId: 'provider-user-1',
              ),
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.providerReviews,
          builder: (_, state) => Scaffold(
            body: Text('reviews-${state.pathParameters['targetId']}'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    final button = find.byKey(const Key('open-provider-reviews'));
    expect(button, findsOneWidget);
    expect(tester.getSize(button).height, greaterThanOrEqualTo(56));
    expect(find.text('Ver reseñas de clientes'), findsOneWidget);
    expect(find.textContaining('opiniones'), findsNothing);
    expect(find.textContaining('de 5'), findsNothing);

    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('reviews-provider-user-1'), findsOneWidget);
  });

  for (final width in [320.0, 430.0]) {
    testWidgets('supports large text at ${width.toInt()} dp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 640),
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: const Scaffold(
              body: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: ProviderReviewsButton(targetId: 'provider-user-1'),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Ver reseñas de clientes'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('open-provider-reviews'))).height,
        greaterThanOrEqualTo(56),
      );
    });
  }
}
