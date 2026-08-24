import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/utils/formatters.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/store_dashboard/billing_balance_card.dart';
import 'package:guiautomotriz_mobile/shared/widgets/dashboard/dashboard.dart';
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

  const dashboardWithCharts = DashboardResponse(
    scope: 'STORE',
    computedAt: '2026-08-24T12:00:00.000Z',
    groups: [
      DashboardGroup(
        title: 'Ventas',
        panels: [
          DashboardPanel(
            id: 'M-T03',
            span: 12,
            metric: MetricResult(
              id: 'M-T03',
              title: 'Flujo de ventas',
              unit: 'count',
              availability: 'AVAILABLE',
              payload: {
                'stages': [
                  {'key': 'SENT', 'label': 'Enviadas', 'value': 12},
                  {'key': 'BOUGHT', 'label': 'Compradas', 'value': 9},
                  {'key': 'DELIVERED', 'label': 'Entregadas', 'value': 7},
                ],
              },
            ),
          ),
          DashboardPanel(
            id: 'M-T11',
            span: 12,
            metric: MetricResult(
              id: 'M-T11',
              title: 'Motivos declinados',
              unit: 'count',
              availability: 'AVAILABLE',
              payload: {
                'total': 10,
                'slices': [
                  {'label': 'Sin stock', 'y': 6},
                  {'label': 'Precio desactualizado', 'y': 3},
                  {'label': 'Fuera de cobertura', 'y': 1},
                ],
              },
            ),
          ),
        ],
      ),
    ],
  );

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

  testWidgets('keeps every KPI and dashboard section visible without data',
      (tester) async {
    const dashboard = DashboardResponse(
      scope: 'STORE',
      computedAt: '2026-08-14T12:00:00.000Z',
      groups: [],
    );
    await tester.pumpWidget(subject((ref) async => dashboard));
    await tester.pumpAndSettle();

    for (final key in const [
      'store-kpi-sales',
      'store-kpi-opportunities',
      'store-kpi-quotes',
      'store-kpi-conversion',
      'store-kpi-cancellation',
      'store-kpi-declined',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget);
    }
    for (final label in const [
      'Ventas',
      'Oportunidades',
      'Cotizaciones',
      'Conversión',
      'Cancelación',
      'Declinadas',
    ]) {
      expect(find.text(label), findsOneWidget);
    }

    expect(find.text('Flujo de ventas'), findsOneWidget);
    expect(
      find.text(
        'Aún no hay movimientos en el flujo de ventas para este período.',
      ),
      findsOneWidget,
    );
    expect(find.text('Motivos de solicitudes declinadas'), findsOneWidget);
    expect(
      find.text('Los motivos no están disponibles en este momento.'),
      findsOneWidget,
    );

    final periodSize = tester.getSize(find.byType(DashboardPeriodSelector));
    expect(periodSize.height, greaterThanOrEqualTo(48));
  });

  testWidgets('renders flow and decline reasons as radial visualizations',
      (tester) async {
    await tester.pumpWidget(subject((ref) async => dashboardWithCharts));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard-conversion-gauge')), findsOneWidget);
    expect(
      find.byKey(const Key('decline-reasons-distribution-chart')),
      findsOneWidget,
    );
    expect(find.text('58%'), findsOneWidget);
    expect(find.text('75% retención'), findsOneWidget);
    expect(find.text('78% retención'), findsOneWidget);
    expect(find.text('Sin stock'), findsOneWidget);
    expect(find.text('60% del total'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chart cards reflow on small and large phones with large text',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in const [Size(320, 720), Size(430, 932)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        subject(
          (ref) async => dashboardWithCharts,
          size: size,
          textScale: 2,
          disableAnimations: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('dashboard-conversion-gauge')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('decline-reasons-distribution-chart')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
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
    for (var index = 0; index < 6; index++) {
      expect(find.byKey(Key('store-kpi-skeleton-$index')), findsOneWidget);
    }
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
    expect(find.textContaining('network error'), findsNothing);
  });

  testWidgets('explains the response-time block instead of a generic error',
      (tester) async {
    const blocked = StoreMetricsBlockedException(
      message: 'Responde más rápido para recuperar el acceso.',
      status: StoreResponseStatus(
        blocked: true,
        medianMinutes: 45,
        thresholdMinutes: 30,
        sampleSize: 12,
        minSample: 10,
        windowDays: 30,
      ),
    );

    await tester.pumpWidget(
      subject((ref) => Future<DashboardResponse>.error(blocked)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard temporalmente bloqueado'), findsOneWidget);
    expect(find.textContaining('Mediana: 45 min'), findsOneWidget);
    expect(find.text('Comprobar de nuevo'), findsOneWidget);
    expect(find.text('Error al cargar dashboard'), findsNothing);
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
