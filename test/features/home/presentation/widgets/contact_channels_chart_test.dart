import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/theme/app_colors.dart';
import 'package:guiautomotriz_mobile/core/theme/app_icons.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/provider_dashboard/contact_channels_chart.dart';

void main() {
  const channels = [
    ContactChannelDatum(
      label: 'Teléfono',
      value: 4,
      icon: AppIcons.call,
      color: AppColors.celesteInk,
    ),
    ContactChannelDatum(
      label: 'WhatsApp',
      value: 6,
      icon: AppIcons.message,
      color: AppColors.successInk,
    ),
    ContactChannelDatum(
      label: 'Instagram',
      value: 0,
      icon: AppIcons.socialContact,
      color: AppColors.primary,
    ),
    ContactChannelDatum(
      label: 'Otros',
      value: 0,
      icon: AppIcons.otherContact,
      color: AppColors.textSecondary,
    ),
  ];

  Widget subject(
    List<ContactChannelDatum> data, {
    Size size = const Size(375, 812),
    double textScale = 1,
  }) =>
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ContactChannelsChart(channels: data),
            ),
          ),
        ),
      );

  testWidgets('uses a distinct bar chart with visible channel readings',
      (tester) async {
    await tester.pumpWidget(subject(channels));
    await tester.pumpAndSettle();

    expect(find.byType(BarChart), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byKey(const Key('dashboard-conversion-gauge')), findsNothing);
    expect(find.text('10 contactos registrados'), findsOneWidget);
    expect(find.text('WhatsApp es tu canal principal'), findsOneWidget);
    expect(find.text('Teléfono'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('Otros'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp(r'Distribución de 10 contactos.*WhatsApp: 6'),
      ),
      findsOneWidget,
    );

    final chart = tester.widget<BarChart>(find.byType(BarChart));
    for (final group in chart.data.barGroups) {
      for (final rod in group.barRods.where((rod) => rod.label.show)) {
        expect(rod.label.offset.dy, greaterThanOrEqualTo(8));
      }
    }
  });

  testWidgets('shows a purposeful zero state instead of flat empty bars',
      (tester) async {
    const emptyChannels = [
      ContactChannelDatum(
        label: 'Teléfono',
        value: 0,
        icon: AppIcons.call,
        color: AppColors.celesteInk,
      ),
      ContactChannelDatum(
        label: 'WhatsApp',
        value: 0,
        icon: AppIcons.message,
        color: AppColors.successInk,
      ),
    ];

    await tester.pumpWidget(subject(emptyChannels));
    await tester.pumpAndSettle();

    expect(find.byType(BarChart), findsNothing);
    expect(
      find.byKey(const Key('contact-channels-zero-state')),
      findsOneWidget,
    );
    expect(find.text('Aún no hay contactos'), findsOneWidget);
    expect(
      find.textContaining('verás aquí qué canal genera más conversaciones'),
      findsOneWidget,
    );
  });

  testWidgets('remains readable on small and large phones with scaled text',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in const [Size(320, 800), Size(430, 932)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        subject(channels, size: size, textScale: 2),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BarChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
