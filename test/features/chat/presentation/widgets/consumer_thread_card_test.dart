import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/service_type.dart';
import 'package:guiautomotriz_mobile/core/theme/app_theme.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_thread.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/widgets/consumer_thread_card.dart';

ChatThread _thread({
  bool isOpen = true,
  bool isExpired = false,
  int totalOffersCount = 0,
  double? bestOfferPrice,
  String? bestOfferStoreName,
  String? bestOfferStatus,
}) {
  return ChatThread(
    id: 'request-1',
    title: 'BMW 5 Series 1984 con un nombre de vehículo largo',
    requestType: ServiceType.spareParts,
    unreadCount: 0,
    conversationCount: 0,
    lastActivityAt: DateTime(2026, 8, 14),
    isOpen: isOpen,
    details: 'Tornillo lateral del banco uno',
    partType: 'ORIGINAL',
    subcategory: 'Motor',
    expiresAt: DateTime.now().add(const Duration(days: 2)),
    isExpired: isExpired,
    totalOffersCount: totalOffersCount,
    bestOfferPrice: bestOfferPrice,
    bestOfferStoreName: bestOfferStoreName,
    bestOfferStatus: bestOfferStatus,
  );
}

Widget _subject(
  ChatThread thread, {
  Size size = const Size(430, 932),
  double textScale = 1,
  VoidCallback? onTap,
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
      ),
      child: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: size.width,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConsumerThreadCard(
                  thread: thread,
                  onTap: onTap ?? () {},
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows a clear waiting state and exposes one card action',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _subject(_thread(), onTap: () => taps++),
    );

    expect(find.text('BUSCANDO'), findsOneWidget);
    expect(find.text('0 cotizaciones'), findsOneWidget);
    expect(find.text('COTIZACIONES'), findsNothing);
    expect(find.text('Esperando respuestas'), findsNothing);
    expect(find.textContaining('Expira en'), findsOneWidget);

    final action = find.bySemanticsLabel(
      RegExp(r'Solicitud BMW 5 Series.*buscando.*Expira en'),
    );
    expect(action, findsOneWidget);
    await tester.tap(action);
    expect(taps, 1);
    expect(tester.takeException(), isNull);

    final card = find.bySemanticsLabel(
      RegExp(r'Solicitud BMW 5 Series.*buscando.*Expira en'),
    );
    final thumbnail = find.byKey(const Key('consumer-request-thumbnail'));
    expect(tester.getSize(thumbnail), const Size(112, 112));
    expect(tester.getSize(card).height, lessThan(200));
  }, semanticsEnabled: true);

  testWidgets('does not count a price-less store inquiry as a quote',
      (tester) async {
    await tester.pumpWidget(
      _subject(_thread(totalOffersCount: 1, bestOfferPrice: null)),
    );

    expect(find.text('BUSCANDO'), findsOneWidget);
    expect(find.text('0 cotizaciones'), findsOneWidget);
    expect(find.text('OFERTAS RECIBIDAS'), findsNothing);
  });

  testWidgets('keeps the best offer readable without turning it into a hero',
      (tester) async {
    await tester.pumpWidget(
      _subject(
        _thread(
          totalOffersCount: 2,
          bestOfferPrice: 1250,
          bestOfferStoreName: 'Repuestos El Pana',
        ),
      ),
    );

    expect(find.text('OFERTAS RECIBIDAS'), findsOneWidget);
    expect(find.text('MEJOR OFERTA'), findsNothing);
    expect(find.textContaining('1,250'), findsOneWidget);
    expect(find.textContaining('Repuestos El Pana'), findsNothing);
    expect(
      find.textContaining('2 cotizaciones', findRichText: true),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides expiration after purchase and names the final outcome',
      (tester) async {
    await tester.pumpWidget(
      _subject(
        _thread(
          totalOffersCount: 1,
          bestOfferPrice: 900,
          bestOfferStoreName: 'Auto Partes Centro',
          bestOfferStatus: 'BOUGHT',
        ),
      ),
    );

    expect(find.text('COMPRADA'), findsOneWidget);
    expect(find.text('OFERTA COMPRADA'), findsNothing);
    expect(find.text('1 cotización'), findsOneWidget);
    expect(find.textContaining('Expira en'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not say it is waiting when a request is already closed',
      (tester) async {
    await tester.pumpWidget(_subject(_thread(isOpen: false)));

    expect(find.text('CERRADA'), findsOneWidget);
    expect(find.text('RESULTADO'), findsNothing);
    expect(find.text('0 cotizaciones'), findsOneWidget);
    expect(find.text('Esperando respuestas'), findsNothing);
    expect(find.textContaining('Expira en'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out safely on a small phone with 200 percent text',
      (tester) async {
    await tester.pumpWidget(
      _subject(
        _thread(
          totalOffersCount: 12,
          bestOfferPrice: 123456.78,
          bestOfferStoreName:
              'Distribuidora Internacional de Repuestos Automotrices',
        ),
        size: const Size(320, 700),
        textScale: 2,
      ),
    );

    expect(find.text('OFERTAS RECIBIDAS'), findsOneWidget);
    expect(
      find.textContaining('12 cotizaciones', findRichText: true),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
