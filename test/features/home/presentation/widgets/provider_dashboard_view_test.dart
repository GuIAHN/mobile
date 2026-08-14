import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/provider_dashboard/provider_dashboard_view.dart';
import 'package:guiautomotriz_mobile/features/reports/domain/entities/store_dashboard.dart';
import 'package:guiautomotriz_mobile/features/reports/presentation/providers/reports_provider.dart';

void main() {
  const dashboard = DashboardResponse(
    scope: 'MECHANIC',
    computedAt: '2026-08-14T12:00:00.000Z',
    groups: [
      DashboardGroup(
        title: 'Perfil',
        panels: [
          DashboardPanel(
            id: 'M-M02',
            span: 3,
            metric: MetricResult(
              id: 'M-M02',
              title: 'Estado de verificación',
              unit: 'count',
              availability: 'AVAILABLE',
              payload: {
                'rows': [
                  {'verified': 'Verificado'},
                ],
              },
            ),
          ),
          DashboardPanel(
            id: 'M-M03',
            span: 3,
            metric: MetricResult(
              id: 'M-M03',
              title: 'Tipo de servicio',
              unit: 'count',
              availability: 'AVAILABLE',
              payload: {
                'rows': [
                  {'type': 'Taller'},
                ],
              },
            ),
          ),
          DashboardPanel(
            id: 'M-M01',
            span: 6,
            metric: MetricResult(
              id: 'M-M01',
              title: 'Cobertura de especialidades',
              unit: 'count',
              availability: 'AVAILABLE',
              payload: {
                'axes': [
                  {'key': 'motor', 'label': 'Motor', 'value': 1, 'max': 1},
                  {'key': 'frenos', 'label': 'Frenos', 'value': 1, 'max': 1},
                ],
              },
            ),
          ),
        ],
      ),
      DashboardGroup(
        title: 'Contacto',
        panels: [
          DashboardPanel(
            id: 'M-M04',
            span: 8,
            metric: MetricResult(
              id: 'M-M04',
              title: 'Clics de contacto',
              unit: 'count',
              availability: 'AVAILABLE',
              payload: {
                'series': [
                  {
                    'points': [
                      {'x': '2026-08-13', 'y': 3},
                      {'x': '2026-08-14', 'y': 7},
                    ],
                  },
                ],
              },
            ),
          ),
          DashboardPanel(
            id: 'KPI-M02',
            span: 4,
            metric: MetricResult(
              id: 'KPI-M02',
              title: 'Tasa de reseñas por contacto',
              unit: 'percent',
              availability: 'AVAILABLE',
              payload: {'value': 25},
            ),
          ),
          DashboardPanel(
            id: 'M-M06',
            span: 6,
            metric: MetricResult(
              id: 'M-M06',
              title: 'Clics de contacto por canal',
              unit: 'count',
              availability: 'AVAILABLE',
              payload: {
                'slices': [
                  {'x': 'PHONE', 'y': 4},
                  {'x': 'WHATSAPP', 'y': 6},
                ],
                'total': 10,
              },
            ),
          ),
          DashboardPanel(
            id: 'M-M07',
            span: 12,
            metric: MetricResult(
              id: 'M-M07',
              title: 'Conversión clic → reseña',
              unit: 'percent',
              availability: 'AVAILABLE',
              payload: {
                'stages': [
                  {'key': 'CLICK', 'label': 'Clic de contacto', 'value': 10},
                  {'key': 'REVIEW', 'label': 'Reseña dejada', 'value': 2},
                ],
              },
            ),
          ),
        ],
      ),
      DashboardGroup(
        title: 'Reputación',
        panels: [
          DashboardPanel(
            id: 'M-M05',
            span: 6,
            metric: MetricResult(
              id: 'M-M05',
              title: 'Calificación promedio',
              unit: 'rating',
              availability: 'DEGRADED',
              payload: {
                'median': 4,
                'buckets': [
                  {'key': '4', 'label': '4★', 'count': 3},
                  {'key': '5', 'label': '5★', 'count': 5},
                ],
              },
            ),
          ),
          DashboardPanel(
            id: 'KPI-M03',
            span: 6,
            metric: MetricResult(
              id: 'KPI-M03',
              title: 'NPS implícito',
              unit: 'nps',
              availability: 'DEGRADED',
              payload: {'value': 50},
            ),
          ),
        ],
      ),
    ],
  );

  Widget subject(
    Future<DashboardResponse> Function(Ref ref) loader, {
    Size size = const Size(375, 812),
    double textScale = 1,
  }) =>
      ProviderScope(
        overrides: [providerDashboardProvider.overrideWith(loader)],
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: ProviderDashboardView()),
            ),
          ),
        ),
      );

  testWidgets('renders real provider profile, contact and reputation metrics',
      (tester) async {
    await tester.pumpWidget(subject((ref) async => dashboard));
    await tester.pumpAndSettle();

    expect(find.text('Perfil verificado'), findsOneWidget);
    expect(find.text('Taller'), findsOneWidget);
    expect(find.text('2 especialidades activas'), findsOneWidget);
    expect(find.text('Contactos'), findsOneWidget);
    expect(find.text('10'), findsWidgets);
    expect(find.text('Reseñas por contacto'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    expect(find.text('Calificación'), findsOneWidget);
    expect(find.text('4.0'), findsOneWidget);
    expect(find.text('NPS'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('Teléfono'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Clic de contacto'), findsOneWidget);
    expect(find.text('Reseña dejada'), findsOneWidget);
  });

  testWidgets('reserves dashboard structure while provider metrics load',
      (tester) async {
    final completer = Completer<DashboardResponse>();
    addTearDown(() {
      if (!completer.isCompleted) completer.complete(dashboard);
    });

    await tester.pumpWidget(subject((ref) => completer.future));
    await tester.pump();

    expect(
        find.byKey(const Key('provider-dashboard-skeleton')), findsOneWidget);
  });

  testWidgets('shows a safe retry state without exposing provider errors',
      (tester) async {
    await tester.pumpWidget(
      subject((ref) => Future.error('private database secret')),
    );
    await tester.pumpAndSettle();

    expect(find.text('No pudimos cargar tus estadísticas'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.textContaining('private database secret'), findsNothing);
  });

  testWidgets('fits provider metrics on representative phones with large text',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in const [Size(375, 812), Size(430, 932)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        subject((ref) async => dashboard, size: size, textScale: 2),
      );
      await tester.pumpAndSettle();

      expect(find.text('Resumen de rendimiento'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
