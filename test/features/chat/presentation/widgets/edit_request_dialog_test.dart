import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/service_type.dart';
import 'package:guiautomotriz_mobile/core/error/failures.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_thread.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/widgets/edit_request_dialog.dart';
import 'package:guiautomotriz_mobile/features/home/domain/repositories/search_repository.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements SearchRepository {}

void main() {
  late _Repository repository;
  setUp(() {
    repository = _Repository();
  });

  Future<void> open(WidgetTester tester,
      {double textScale = 1, double keyboardInset = 0}) async {
    await tester.pumpWidget(ProviderScope(
        overrides: [searchRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(textScale),
                  viewInsets: EdgeInsets.only(bottom: keyboardInset),
                  disableAnimations: true,
                  padding: const EdgeInsets.only(top: 44, bottom: 34)),
              child: child!),
          home: Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                      onPressed: () => EditRequestDialog.show(
                          context,
                          ChatThread(
                              id: 'r',
                              title: 'Batería',
                              requestType: ServiceType.spareParts,
                              unreadCount: 0,
                              conversationCount: 0,
                              lastActivityAt: DateTime.now(),
                              quantity: 3,
                              details: 'Batería original')),
                      child: const Text('Editar')))),
        )));
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
  }

  testWidgets('saves only editable fields and closes after success',
      (tester) async {
    when(() => repository.updateSearchRequest(
        requestId: 'r',
        details: 'Con sensor',
        photoUrls: [])).thenAnswer((_) async => const Right({'id': 'r'}));
    await open(tester);
    await tester.enterText(
        find.byKey(const Key('edit-request-details')), 'Con sensor');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-request')));
    await tester.pumpAndSettle();
    verify(() => repository.updateSearchRequest(
        requestId: 'r', details: 'Con sensor', photoUrls: [])).called(1);
    expect(find.byType(EditRequestDialog), findsNothing);
  });

  testWidgets('handles a concurrent quote by locking the editor',
      (tester) async {
    when(() => repository.updateSearchRequest(
            requestId: 'r', details: 'Con sensor', photoUrls: []))
        .thenAnswer((_) async => const Left(RequestNotEditableFailure()));
    await open(tester);
    await tester.enterText(
        find.byKey(const Key('edit-request-details')), 'Con sensor');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-request')));
    await tester.pumpAndSettle();
    expect(
        find.text(const RequestNotEditableFailure().message), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('save-request')))
            .onPressed,
        isNull);
    expect(find.text('Con sensor'), findsOneWidget);
  });

  testWidgets('blocks duplicate saves and closing while the server responds',
      (tester) async {
    final pending = Completer<Either<Failure, Map<String, dynamic>>>();
    when(() => repository.updateSearchRequest(
        requestId: 'r',
        details: 'Con sensor',
        photoUrls: [])).thenAnswer((_) => pending.future);
    await open(tester);
    await tester.enterText(
        find.byKey(const Key('edit-request-details')), 'Con sensor');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-request')));
    await tester.pump();
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('save-request')))
            .onPressed,
        isNull);
    expect(
        tester
            .widget<IconButton>(find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Cerrar edición'))
            .onPressed,
        isNull);
    pending.complete(const Right({'id': 'r'}));
    await tester.pumpAndSettle();
  });

  for (final width in [320.0, 430.0]) {
    testWidgets('supports a $width phone with large text and safe areas',
        (tester) async {
      tester.view.physicalSize = Size(width, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await open(tester, textScale: 2);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byTooltip('Cerrar edición')).shortestSide,
          greaterThanOrEqualTo(48));
      expect(tester.getTopLeft(find.byTooltip('Cerrar edición')).dy,
          greaterThanOrEqualTo(44));
      expect(tester.getBottomRight(find.byKey(const Key('save-request'))).dy,
          lessThanOrEqualTo(932 - 34));
    });

    testWidgets('keeps save visible above the keyboard at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await open(tester, textScale: 2, keyboardInset: 300);
      await tester.scrollUntilVisible(
          find.byKey(const Key('edit-request-details')), 100,
          scrollable: find.byType(Scrollable).first);
      await tester.showKeyboard(find.byKey(const Key('edit-request-details')));
      await tester.pumpAndSettle();
      expect(tester.getBottomRight(find.byKey(const Key('save-request'))).dy,
          lessThanOrEqualTo(932 - 300));
      expect(tester.takeException(), isNull);
    });
  }
}
