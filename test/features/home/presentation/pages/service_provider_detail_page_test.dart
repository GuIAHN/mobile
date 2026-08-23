import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/service_type.dart';
import 'package:guiautomotriz_mobile/core/theme/app_colors.dart';
import 'package:guiautomotriz_mobile/core/theme/app_icons.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/provider_detail.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/pages/mechanic_detail_page.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/pages/store_detail_page.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/provider_detail_widgets.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/widgets/service_provider_detail_view.dart';
import 'package:guiautomotriz_mobile/shared/widgets/guia_map.dart';

typedef _DetailLoader = Future<ProviderDetail> Function(
  ({String id, ServiceType type}) args,
);

const _description =
    'Somos especialistas en diagnóstico automotriz, frenos y mantenimiento '
    'preventivo. Trabajamos con herramientas actualizadas y explicamos cada '
    'reparación antes de comenzar para que el conductor pueda decidir con claridad.';

ProviderDetail _fixture({
  bool isWorkshop = false,
  bool empty = false,
  List<String>? specialties,
}) {
  return ProviderDetail(
    id: isWorkshop ? 'workshop-1' : 'mechanic-1',
    nombre: isWorkshop ? 'Taller Auto-Sport' : 'Carlos Mendoza',
    esTaller: isWorkshop,
    descripcion: empty ? null : _description,
    rating: empty ? null : 4.8,
    ratingCount: empty ? 0 : 24,
    tarifa: empty ? null : 35,
    distanciaKm: empty ? null : 2.4,
    especialidades: empty
        ? const []
        : specialties ??
            const ['Diagnóstico', 'Frenos', 'Electricidad', 'Alineación'],
    verified: !empty,
    telefono: empty ? null : '02129999999',
    direccion: empty ? null : 'Av. Principal, Caracas',
    lat: empty ? null : 10.5438,
    lng: empty ? null : -66.8576,
  );
}

Widget _subject({
  required _DetailLoader load,
  ServiceType type = ServiceType.mechanic,
  Size size = const Size(390, 844),
  EdgeInsets padding = const EdgeInsets.only(top: 44, bottom: 20),
  double textScale = 1,
  bool disableAnimations = true,
}) {
  final page = type == ServiceType.mechanic
      ? const MechanicDetailPage(mechanicId: 'mechanic-1')
      : const StoreDetailPage(
          storeId: 'workshop-1',
          serviceType: ServiceType.workshops,
        );

  return ProviderScope(
    key: UniqueKey(),
    overrides: [providerDetailProvider.overrideWith((ref, args) => load(args))],
    child: MediaQuery(
      data: MediaQueryData(
        size: size,
        padding: padding,
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: MaterialApp(home: page),
    ),
  );
}

Future<void> _pumpResolved(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('groups the mechanic information and keeps contact actions fixed',
      (tester) async {
    await _pumpResolved(
      tester,
      _subject(load: (_) async => _fixture()),
    );

    expect(find.text('Carlos Mendoza'), findsOneWidget);
    expect(
      find.byKey(const Key('service-provider-overview-card')),
      findsOneWidget,
    );
    expect(find.text('4.8'), findsOneWidget);
    expect(find.text('24 reseñas'), findsOneWidget);
    expect(find.text('2.4 km'), findsOneWidget);
    expect(find.text(r'$35'), findsOneWidget);
    expect(find.text('Diagnóstico · Frenos · +2'), findsOneWidget);
    expect(find.byKey(const Key('service-provider-call')), findsOneWidget);
    expect(find.byKey(const Key('service-provider-whatsapp')), findsOneWidget);
    expect(find.byIcon(AppIcons.services), findsOneWidget);
    expect(find.byIcon(Icons.handyman_outlined), findsNothing);

    final heroRect = tester.getRect(
      find.byKey(const Key('service-provider-hero')),
    );
    final overviewRect = tester.getRect(
      find.byKey(const Key('service-provider-overview-card')),
    );
    expect(overviewRect.top, greaterThanOrEqualTo(heroRect.bottom));

    final scrollRect = tester.getRect(
      find.byKey(const Key('service-provider-detail-scroll')),
    );
    final contactBarRect = tester.getRect(
      find.byKey(const Key('service-provider-contact-bar')),
    );
    expect(scrollRect.bottom, lessThanOrEqualTo(contactBarRect.top));

    final whatsappText = tester.widget<Text>(find.text('WhatsApp'));
    expect(whatsappText.style?.color, AppColors.textOnPrimary);

    // El mapa y el listado completo ya no alargan el contenido inicial.
    expect(find.byType(GuiaMap), findsNothing);
    expect(find.byType(DetailContactTile), findsNothing);
    expect(find.text('Alineación'), findsNothing);

    await tester.tap(
      find.byKey(const Key('service-provider-services-row')),
    );
    await tester.pump();

    expect(find.text('Servicios que ofrece'), findsOneWidget);
    expect(find.text('Alineación'), findsOneWidget);
    expect(find.byType(DetailChip), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('provider-detail-sheet'))).height,
      lessThan(420),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('sizes service and location sheets to their content',
      (tester) async {
    await _pumpResolved(
      tester,
      _subject(
        load: (_) async => _fixture(
          specialties: const ['Diagnóstico computarizado'],
        ),
      ),
    );

    await tester.tap(
      find.byKey(const Key('service-provider-services-row')),
    );
    await tester.pump();

    expect(
      tester.getSize(find.byKey(const Key('provider-detail-sheet'))).height,
      lessThan(260),
    );

    await tester.tap(find.byIcon(AppIcons.close));
    await tester.pump();
    final locationRow = find.byKey(const Key('service-provider-location-row'));
    await tester.ensureVisible(locationRow);
    await tester.pump();
    await tester.tap(locationRow);
    await tester.pump();

    expect(find.byType(DetailLocationCard), findsOneWidget);
    expect(find.byType(GuiaMap), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('provider-detail-sheet'))).height,
      lessThan(600),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the compact experience for workshop details too',
      (tester) async {
    await _pumpResolved(
      tester,
      _subject(
        type: ServiceType.workshops,
        load: (_) async => _fixture(isWorkshop: true),
      ),
    );

    expect(find.text('Taller Auto-Sport'), findsOneWidget);
    expect(find.text('Taller mecánico'), findsOneWidget);
    expect(
      find.byKey(const Key('service-provider-overview-card')),
      findsOneWidget,
    );
    expect(find.byType(DetailLocationCard), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows honest fallbacks when optional provider data is empty',
      (tester) async {
    await _pumpResolved(
      tester,
      _subject(load: (_) async => _fixture(empty: true)),
    );

    expect(find.text('Nuevo'), findsOneWidget);
    expect(find.text('Sin reseñas'), findsOneWidget);
    expect(find.text('Sin dato'), findsOneWidget);
    expect(find.text('Consultar'), findsOneWidget);
    expect(find.text('Servicios por confirmar'), findsOneWidget);
    expect(
      find.text('Este proveedor aún no agregó una presentación.'),
      findsOneWidget,
    );
    expect(find.text('Ubicación por confirmar'), findsOneWidget);
    expect(
      find.text('El proveedor aún no publicó un teléfono'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('service-provider-call')), findsNothing);
    expect(find.byKey(const Key('service-provider-whatsapp')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps distinct loading and safe recoverable error states',
      (tester) async {
    final pending = Completer<ProviderDetail>();
    await tester.pumpWidget(_subject(load: (_) => pending.future));
    await tester.pump();

    expect(find.byType(ServiceProviderDetailSkeleton), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _pumpResolved(
      tester,
      _subject(
        load: (_) async => throw StateError('internal SQL connection details'),
      ),
    );

    expect(find.text('No se pudo cargar el perfil'), findsOneWidget);
    expect(
      find.text(
        'No pudimos cargar los datos. Revisa tu conexión e inténtalo nuevamente.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('internal SQL'), findsNothing);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'remains layout-safe with safe areas, reduced motion and text scaling',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final flutterErrors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = flutterErrors.add;
    addTearDown(() => FlutterError.onError = previousOnError);

    final cases = [
      (const Size(320, 720), 2.0),
      (const Size(480, 932), 1.0),
    ];

    for (final layout in cases) {
      await tester.binding.setSurfaceSize(layout.$1);
      await _pumpResolved(
        tester,
        _subject(
          load: (_) async => _fixture(),
          size: layout.$1,
          padding: const EdgeInsets.only(top: 44, bottom: 28),
          textScale: layout.$2,
        ),
      );

      expect(find.text('Carlos Mendoza'), findsOneWidget);
      expect(find.byKey(const Key('service-provider-call')), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('service-provider-call'))).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester
            .getSize(find.byKey(const Key('service-provider-whatsapp')))
            .height,
        greaterThanOrEqualTo(48),
      );
      expect(tester.takeException(), isNull);
    }

    expect(
      flutterErrors.where(
        (details) => details.exceptionAsString().contains('overflowed'),
      ),
      isEmpty,
    );
    expect(flutterErrors, isEmpty);
  });
}
