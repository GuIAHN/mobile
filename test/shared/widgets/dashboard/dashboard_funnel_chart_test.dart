import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/theme/app_colors.dart';
import 'package:guiautomotriz_mobile/shared/widgets/dashboard/dashboard.dart';

void main() {
  const steps = [
    DashboardFunnelStep(
      name: 'Enviadas',
      count: 10,
      color: AppColors.tertiary,
    ),
    DashboardFunnelStep(
      name: 'Compradas',
      count: 8,
      color: AppColors.primary,
    ),
    DashboardFunnelStep(
      name: 'Entregadas',
      count: 6,
      color: AppColors.successInk,
    ),
  ];

  Widget subject({double textScale = 1}) {
    return MediaQuery(
      data: MediaQueryData(
        size: const Size(375, 900),
        textScaler: TextScaler.linear(textScale),
      ),
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: DashboardFunnelChart(steps: steps),
          ),
        ),
      ),
    );
  }

  testWidgets('renders conversion as an instrument with exact stage readings',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(375, 900));
    await tester.pumpWidget(subject());

    expect(find.byKey(const Key('dashboard-conversion-gauge')), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('Enviadas'), findsOneWidget);
    expect(find.text('Compradas'), findsOneWidget);
    expect(find.text('Entregadas'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reflows its readings for large text on a small phone',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(375, 1100));
    await tester.pumpWidget(subject(textScale: 2));

    expect(find.text('Inicio del flujo'), findsOneWidget);
    expect(find.text('80% retención'), findsOneWidget);
    expect(find.text('75% retención'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
