import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/utils/formatters.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/store_dashboard/billing_balance_card.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/store_dashboard/store_dashboard_view.dart';
import 'package:guiautomotriz_mobile/features/reports/domain/entities/store_dashboard.dart';
import 'package:guiautomotriz_mobile/features/reports/presentation/providers/reports_provider.dart';

void main() {
  DashboardResponse dashboardWithBalance(Object? value) {
    return DashboardResponse(
      scope: 'STORE',
      computedAt: '2026-08-14T12:00:00.000Z',
      groups: [
        DashboardGroup(
          title: 'Ventas',
          panels: [
            DashboardPanel(
              id: 'M-T10',
              span: 4,
              metric: MetricResult(
                id: 'M-T10',
                title: 'Saldo pendiente con GuIA-HN',
                subtitle: 'Comisión sin pagar',
                unit: 'currency_hnl',
                availability: 'AVAILABLE',
                payload: {'value': value},
              ),
            ),
          ],
        ),
      ],
    );
  }

  DashboardResponse dashboardWithGrossSales(num value) {
    return DashboardResponse(
      scope: 'STORE',
      computedAt: '2026-08-20T12:00:00.000Z',
      groups: [
        DashboardGroup(
          title: 'Ventas',
          panels: [
            DashboardPanel(
              id: 'M-T06',
              span: 8,
              metric: MetricResult(
                id: 'M-T06',
                title: 'Ventas brutas (GMV)',
                unit: 'currency_hnl',
                availability: 'AVAILABLE',
                payload: {'value': value, 'deltaPct': 12.5},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget subject(
    Future<DashboardResponse> Function(Ref ref) loadDashboard, {
    Size size = const Size(375, 812),
    double textScale = 1,
    bool disableAnimations = false,
  }) {
    return ProviderScope(
      overrides: [
        storeDashboardProvider.overrideWith(loadDashboard),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StoreDashboardView(),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows the outstanding balance already returned by dashboard',
      (tester) async {
    const amount = 1234.5;
    await tester.pumpWidget(
      subject((ref) async => dashboardWithBalance(amount)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BillingBalanceCard), findsOneWidget);
    expect(find.text('Saldo pendiente con GuIA'), findsOneWidget);
    expect(find.text(Formatters.currency(amount)), findsOneWidget);
    expect(
      find.text('Comisión pendiente por ventas realizadas en la app'),
      findsOneWidget,
    );
  });

  testWidgets('shows an explicit paid-up state when balance is zero',
      (tester) async {
    await tester.pumpWidget(
      subject((ref) async => dashboardWithBalance(0)),
    );
    await tester.pumpAndSettle();

    expect(find.text(Formatters.currency(0)), findsOneWidget);
    expect(find.text('Estás al día'), findsOneWidget);
  });

  testWidgets('shows the M-T06 gross sales value in the activity card',
      (tester) async {
    await tester.pumpWidget(
      subject((ref) async => dashboardWithGrossSales(1540.75)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ventas'), findsOneWidget);
    expect(find.text(r'$ 1540.75'), findsOneWidget);
  });

  testWidgets('does not invent an amount when M-T10 is absent', (tester) async {
    const dashboard = DashboardResponse(
      scope: 'STORE',
      computedAt: '2026-08-14T12:00:00.000Z',
      groups: [],
    );
    await tester.pumpWidget(subject((ref) async => dashboard));
    await tester.pumpAndSettle();

    expect(find.text('No disponible'), findsOneWidget);
    expect(
      find.text('No pudimos obtener el saldo en este momento'),
      findsOneWidget,
    );
  });

  testWidgets('reserves balance space while dashboard loads', (tester) async {
    final completer = Completer<DashboardResponse>();
    addTearDown(() {
      if (!completer.isCompleted) {
        completer.complete(const DashboardResponse(
          scope: 'STORE',
          computedAt: '',
          groups: [],
        ));
      }
    });

    await tester.pumpWidget(subject((ref) => completer.future));
    await tester.pump();

    expect(find.byKey(const Key('store-billing-balance-skeleton')),
        findsOneWidget);
  });

  testWidgets('keeps the dashboard retry state when loading fails',
      (tester) async {
    await tester.pumpWidget(
      subject((ref) => Future<DashboardResponse>.error('network error')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Error al cargar dashboard'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.byType(BillingBalanceCard), findsNothing);
  });

  testWidgets('balance card adapts to representative phones and large text',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in const [Size(375, 812), Size(430, 932)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        subject(
          (ref) async => dashboardWithBalance(9876543.21),
          size: size,
          textScale: 2,
          disableAnimations: true,
        ),
      );
      await tester.pumpAndSettle();

      final cardRect = tester.getRect(
        find.byKey(const Key('store-billing-balance-card')),
      );
      expect(cardRect.left, greaterThanOrEqualTo(0));
      expect(cardRect.right, lessThanOrEqualTo(size.width));
      expect(tester.takeException(), isNull);
    }
  });
}
