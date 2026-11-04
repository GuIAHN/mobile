import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/services/app_update_service.dart';
import 'package:guiautomotriz_mobile/core/theme/app_colors.dart';
import 'package:guiautomotriz_mobile/shared/widgets/app_update_gate.dart';
import 'package:upgrader/upgrader.dart';

class _UpdateService extends AppUpdateService {
  final ready = Completer<bool>();
  bool available = false;
  bool hasStoreUrl = true;
  int alerts = 0;
  int launches = 0;

  @override
  Future<bool> initialize() async {
    final result = await ready.future;
    updateState(state.copyWith(
      versionInfo: UpgraderVersionInfo(
        appStoreListingURL:
            hasStoreUrl ? 'https://apps.apple.com/app/id123' : null,
      ),
    ));
    return result;
  }

  @override
  bool shouldDisplayUpgrade() => available;

  @override
  Future<bool> saveLastAlerted() async {
    alerts++;
    return true;
  }

  @override
  Future<bool> openStore() async {
    launches++;
    return true;
  }
}

Future<void> _pumpGate(
  WidgetTester tester,
  _UpdateService service,
  RootBackButtonDispatcher dispatcher,
) async {
  dispatcher.addCallback(() async => false);
  await tester.pumpWidget(ProviderScope(
    overrides: [appUpdateServiceProvider.overrideWithValue(service)],
    child: MaterialApp(
      home: AppUpdateGate(
        backButtonDispatcher: dispatcher,
        child: const Scaffold(body: Text('Contenido de la app')),
      ),
    ),
  ));
}

void main() {
  testWidgets('store check and no update leave the app available',
      (tester) async {
    final service = _UpdateService();
    addTearDown(service.dispose);
    await _pumpGate(tester, service, RootBackButtonDispatcher());
    expect(find.text('Contenido de la app'), findsOneWidget);
    expect(find.byType(AppUpdateDialog), findsNothing);
    service.ready.complete(false);
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateDialog), findsNothing);
    expect(service.alerts, 0);
  });

  testWidgets('optional notice dismisses and can notify on a later resume',
      (tester) async {
    final service = _UpdateService()..available = true;
    addTearDown(service.dispose);
    final dispatcher = RootBackButtonDispatcher();
    await _pumpGate(tester, service, dispatcher);
    service.ready.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('Nueva actualización'), findsOneWidget);
    expect(service.alerts, 1);
    await tester.tap(find.text('Más tarde'));
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateDialog), findsNothing);
    expect(find.text('Contenido de la app'), findsOneWidget);
    service.updateStream();
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateDialog), findsOneWidget);
    expect(await dispatcher.didPopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateDialog), findsNothing);
  });

  testWidgets('users can continue without updating after opening the store',
      (tester) async {
    final service = _UpdateService()..available = true;
    addTearDown(service.dispose);
    final dispatcher = RootBackButtonDispatcher();
    await _pumpGate(tester, service, dispatcher);
    service.ready.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('Más tarde'), findsOneWidget);
    await tester.tap(find.text('ACTUALIZAR'));
    await tester.pumpAndSettle();
    expect(service.launches, 1);
    await tester.tap(find.text('Más tarde'));
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateDialog), findsNothing);
    expect(find.text('Contenido de la app'), findsOneWidget);
  });

  testWidgets('missing store URL never traps the user', (tester) async {
    final service = _UpdateService()
      ..available = true
      ..hasStoreUrl = false;
    addTearDown(service.dispose);
    await _pumpGate(tester, service, RootBackButtonDispatcher());
    service.ready.complete(true);
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateDialog), findsNothing);
    expect(service.alerts, 0);
  });

  testWidgets('remote minimum and critical flags never prevent continuing',
      (tester) async {
    final service = _UpdateService()..available = true;
    addTearDown(service.dispose);
    final dispatcher = RootBackButtonDispatcher();
    await _pumpGate(tester, service, dispatcher);
    service.ready.complete(true);
    await tester.pumpAndSettle();
    service.updateState(service.state.copyWith(
      versionInfo: UpgraderVersionInfo(
        appStoreListingURL: 'https://apps.apple.com/app/id123',
        minAppVersion: Upgrader.parseVersion('999.0.0', 'minimum', false),
        isCriticalUpdate: true,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Más tarde'), findsOneWidget);
    expect(find.text('Actualiza para continuar'), findsNothing);
    await tester.tap(find.text('Más tarde'));
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateDialog), findsNothing);
    expect(find.text('Contenido de la app'), findsOneWidget);
    service.updateStream();
    await tester.pumpAndSettle();
    expect(await dispatcher.didPopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateDialog), findsNothing);
    expect(find.text('Contenido de la app'), findsOneWidget);
  });

  testWidgets('disposal during the store check does not update a dead widget',
      (tester) async {
    final service = _UpdateService()..available = true;
    addTearDown(service.dispose);
    await _pumpGate(tester, service, RootBackButtonDispatcher());
    await tester.pumpWidget(const SizedBox.shrink());
    service.ready.complete(true);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening state prevents repeated taps and failures allow retry',
      (tester) async {
    final pending = Completer<bool>();
    var calls = 0;
    var continued = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppUpdateDialog(
          onLater: () => continued = true,
          onUpdate: () {
            calls++;
            return calls == 1
                ? pending.future
                : Future<bool>.error(Exception('store unavailable'));
          },
        ),
      ),
    ));
    await tester.tap(find.text('ACTUALIZAR'));
    await tester.pump();
    expect(find.text('ABRIENDO…'), findsOneWidget);
    expect(tester.widget<TextButton>(find.byType(TextButton)).onPressed,
        isNotNull);
    await tester.tap(find.text('ABRIENDO…'));
    expect(calls, 1);
    pending.complete(false);
    await tester.pumpAndSettle();
    expect(find.textContaining('No se pudo abrir la página de actualización.'), findsOneWidget);
    await tester.tap(find.text('ACTUALIZAR'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.textContaining('No se pudo abrir la página de actualización.'), findsOneWidget);
    await tester.ensureVisible(find.text('Más tarde'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Más tarde'));
    expect(continued, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'notice supports small and large phones, landscape, scaling and reduced motion',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    for (final size in [
      const Size(320, 568),
      const Size(430, 932),
      const Size(844, 390)
    ]) {
      tester.view.physicalSize = size;
      for (final scale in [1.0, 2.0, 3.0]) {
        await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              padding: const EdgeInsets.only(top: 44, bottom: 34),
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: SafeArea(
              child: AppUpdateDialog(
                version: '1.0.9',
                onUpdate: () async => false,
                onLater: () {},
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$size at ${scale}x');
        await tester.ensureVisible(find.text('ACTUALIZAR'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ACTUALIZAR'));
        await tester.pumpAndSettle();
        expect(
            find.textContaining('No se pudo abrir la página de actualización.'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(ElevatedButton)).height,
            greaterThanOrEqualTo(48));
        await tester.ensureVisible(find.text('Más tarde'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Más tarde'));
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('notice provides accessible targets, labels and text contrast',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppUpdateDialog(
          onUpdate: () async => true,
          onLater: () {},
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    final buttonContrast = (Colors.white.computeLuminance() + 0.05) /
        (AppColors.primary.computeLuminance() + 0.05);
    expect(buttonContrast, greaterThanOrEqualTo(3));
    final bodyContrast = (AppColors.background.computeLuminance() + 0.05) /
        (AppColors.textPrimary.computeLuminance() + 0.05);
    expect(bodyContrast, greaterThanOrEqualTo(4.5));
    handle.dispose();
  });
}
