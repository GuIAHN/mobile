import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/providers/paged_list_notifier.dart';
import 'package:guiautomotriz_mobile/core/theme/app_colors.dart';
import 'package:guiautomotriz_mobile/shared/widgets/paged_list_body.dart';

void main() {
  for (final width in [320.0, 430.0]) {
    for (final mode in ['loading', 'error', 'empty', 'data']) {
      testWidgets(
          '$mode at width $width respects text scaling, safe areas and reduced motion',
          (tester) async {
        tester.view.physicalSize = Size(width, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var retries = 0;
        final state = PagedListState<int>(
          items: mode == 'empty' ? [] : [1],
          canLoadMore: mode == 'loading' || mode == 'error',
          isLoadingMore: mode == 'loading',
          loadMoreError: mode == 'error' ? 'offline' : null,
        );
        await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(2),
                  disableAnimations: true,
                  padding: const EdgeInsets.only(top: 40, bottom: 34)),
              child: child!),
          home: Scaffold(
              backgroundColor: AppColors.background,
              body: SafeArea(
                  child: PagedListBody(
                state: state,
                itemCount: state.items.length,
                itemBuilder: (_, index) => const Text('Solicitud disponible'),
                empty: const Text('Sin solicitudes'),
                onLoadMore: () async {
                  retries++;
                },
                onRefresh: () async {},
                padding: const EdgeInsets.all(24),
              ))),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(
            find.text(
                mode == 'empty' ? 'Sin solicitudes' : 'Solicitud disponible'),
            findsOneWidget);
        if (mode == 'error') {
          final button = find.byType(OutlinedButton);
          expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
          expect(tester.getRect(button).bottom, lessThanOrEqualTo(706));
          expect(retries, 0); // Failed loads never retry in a loop.
          await tester.tap(button);
          expect(retries, 1);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        }
        if (mode == 'loading') {
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          expect(retries, 0);
        }
      }, semanticsEnabled: true);
    }
  }

  test(
      'pagination copy and controls have accessible contrast on the project background',
      () {
    final text = AppColors.textPrimary.computeLuminance();
    final background = AppColors.background.computeLuminance();
    expect((background + .05) / (text + .05), greaterThanOrEqualTo(4.5));
  });

  testWidgets(
      'fills a short viewport and completes a local search without duplicate loads',
      (tester) async {
    var calls = 0;
    final pending = Completer<void>();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PagedListBody<int>(
      state: const PagedListState(items: [], canLoadMore: true),
      itemCount: 0,
      itemBuilder: (_, __) => const SizedBox(),
      empty: const Text('Sin resultados'),
      completeSearch: true,
      onLoadMore: () {
        calls++;
        return pending.future;
      },
      onRefresh: () async {},
      padding: const EdgeInsets.all(24),
    ))));
    await tester.pump();
    expect(calls, 1);
    expect(find.text('Sin resultados'), findsNothing);
    expect(find.text('Buscando en más resultados…'), findsOneWidget);
    pending.complete();
  });
}
